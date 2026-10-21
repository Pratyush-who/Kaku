package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "embed"

	_ "github.com/lib/pq"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/config"
	"github.com/Pratyush-who/Kaku/backend/internal/handlers"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

func main() {
	cfg := config.Load()

	// Connect to PostgreSQL
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Quick ping check
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	if err := db.PingContext(ctx); err != nil {
		log.Printf("Warning: Database ping failed (will retry on requests): %v", err)
	} else {
		log.Printf("Connected to PostgreSQL successfully")
		// Automatically ensure database schema is applied
		if err := autoMigrate(db); err != nil {
			log.Printf("Warning: Database schema auto-migration check: %v", err)
		} else {
			log.Printf("Database schema is ready and verified")
		}
	}
	cancel()

	// Services & Repositories
	repo := repository.NewPostgresRepository(db)
	tokenService := auth.NewTokenService(cfg.JWTSecret, cfg.JWTExpiresIn)

	// Handlers
	authHandler := handlers.NewAuthHandler(repo, tokenService, cfg.BcryptCost)
	projectHandler := handlers.NewProjectHandler(repo)
	boardHandler := handlers.NewBoardHandler(repo)
	invitationHandler := handlers.NewInvitationHandler(repo)

	// Router setup
	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		httputil.JSON(w, http.StatusOK, map[string]string{
			"status": "healthy",
			"time":   time.Now().UTC().Format(time.RFC3339),
		})
	})

	// Public Auth Endpoints
	mux.HandleFunc("/api/v1/auth/register", authHandler.Register)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)

	// Protected Endpoints (Wrapped with AuthMiddleware)
	authMW := middleware.AuthMiddleware(tokenService)

	// User Profile Endpoints
	mux.Handle("/api/v1/me", authMW(http.HandlerFunc(authHandler.Me)))
	mux.Handle("/api/v1/me/password", authMW(http.HandlerFunc(authHandler.ChangePassword)))

	// /api/v1/projects and /api/v1/projects/
	mux.Handle("/api/v1/projects", authMW(http.HandlerFunc(projectHandler.HandleProjects)))
	mux.Handle("/api/v1/projects/", authMW(http.HandlerFunc(projectHandler.HandleProjectByID)))

	// /api/v1/boards and /api/v1/boards/
	mux.Handle("/api/v1/boards", authMW(http.HandlerFunc(boardHandler.HandleBoardByID)))
	mux.Handle("/api/v1/boards/", authMW(http.HandlerFunc(boardHandler.HandleBoardByID)))

	// Invitations (inspection is public, accepting requires auth)
	invitationMuxFunc := func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			// Accepting requires auth
			authMW(http.HandlerFunc(invitationHandler.HandleInvitation)).ServeHTTP(w, r)
		} else {
			// Inspection / GET is public
			invitationHandler.HandleInvitation(w, r)
		}
	}
	mux.HandleFunc("/api/v1/invitations", invitationMuxFunc)
	mux.HandleFunc("/api/v1/invitations/", invitationMuxFunc)

	// Global Middlewares (CORS & Logging)
	handler := middleware.Logger(middleware.CORS(mux))

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Kaku backend server starting on port %s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server gracefully...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exiting")
}
//go:embed migrations/000001_init_schema.up.sql
var schemaSQL string

func autoMigrate(db *sql.DB) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err := db.ExecContext(ctx, schemaSQL)
	return err
}
