package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	_ "embed"

	_ "github.com/lib/pq"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/collab"
	"github.com/Pratyush-who/Kaku/backend/internal/config"
	"github.com/Pratyush-who/Kaku/backend/internal/handlers"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
	"github.com/Pratyush-who/Kaku/backend/internal/middleware"
	"github.com/Pratyush-who/Kaku/backend/internal/repository"
)

func main() {
	cfg := config.Load()

	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	if err := db.PingContext(ctx); err != nil {
		log.Printf("Warning: Database ping failed (will retry on requests): %v", err)
	} else {
		log.Printf("Connected to PostgreSQL successfully")
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
	profileHandler := handlers.NewProfileHandler(repo, tokenService, cfg.BcryptCost, "./uploads")
	projectHandler := handlers.NewProjectHandler(repo)
	collabHub := collab.NewHub(repo, tokenService)
	boardHandler := handlers.NewBoardHandler(repo, collabHub, cfg.BcryptCost)
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

	mux.HandleFunc("/api/v1/auth/register", authHandler.Register)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)

	mux.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("./uploads"))))

	authMW := middleware.AuthMiddleware(tokenService)

	mux.Handle("/api/v1/me", authMW(http.HandlerFunc(profileHandler.HandleMe)))
	mux.Handle("/api/v1/me/", authMW(http.HandlerFunc(profileHandler.HandleMeSubpaths)))
	mux.Handle("/api/v1/profile", authMW(http.HandlerFunc(profileHandler.HandleMe)))
	mux.Handle("/api/v1/profile/", authMW(http.HandlerFunc(profileHandler.HandleMeSubpaths)))

	mux.Handle("/api/v1/projects", authMW(http.HandlerFunc(projectHandler.HandleProjects)))
	mux.Handle("/api/v1/projects/", authMW(http.HandlerFunc(projectHandler.HandleProjectByID)))

	// User Autocomplete & Search (Google Drive style email / name search)
	mux.Handle("/api/v1/users/search", authMW(http.HandlerFunc(projectHandler.HandleSearchUsers)))
	mux.Handle("/api/v1/search", authMW(http.HandlerFunc(projectHandler.HandleGlobalSearch)))

	boardMuxFunc := func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/ws") {
			collabHub.ServeWS(w, r)
			return
		}
		authMW(http.HandlerFunc(boardHandler.HandleBoardByID)).ServeHTTP(w, r)
	}

	mux.HandleFunc("/api/v1/boards", boardMuxFunc)
	mux.HandleFunc("/api/v1/boards/", boardMuxFunc)

	mux.HandleFunc("/api/v1/shared/boards/", boardHandler.HandleSharedBoard)

	// Public Shared Projects & Joining
	sharedProjectMuxFunc := func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/join") {
			authMW(http.HandlerFunc(projectHandler.HandleSharedProject)).ServeHTTP(w, r)
		} else {
			projectHandler.HandleSharedProject(w, r)
		}
	}
	mux.HandleFunc("/api/v1/shared/projects/", sharedProjectMuxFunc)

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

//go:embed migrations/000002_add_profile_fields.up.sql
var profileFieldsSQL string

//go:embed migrations/000003_board_management_and_collaboration.up.sql
var boardCollabSQL string

//go:embed migrations/000004_project_sharing_and_search.up.sql
var projectSharingSQL string

func autoMigrate(db *sql.DB) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if _, err := db.ExecContext(ctx, schemaSQL); err != nil {
		return err
	}
	if _, err := db.ExecContext(ctx, profileFieldsSQL); err != nil {
		return err
	}
	if _, err := db.ExecContext(ctx, boardCollabSQL); err != nil {
		return err
	}
	if _, err := db.ExecContext(ctx, projectSharingSQL); err != nil {
		return err
	}
	return nil
}
