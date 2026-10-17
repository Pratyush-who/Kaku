package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/Pratyush-who/Kaku/backend/internal/auth"
	"github.com/Pratyush-who/Kaku/backend/internal/httputil"
)

type contextKey string

const (
	UserContextKey  contextKey = "authUser"
	EmailContextKey contextKey = "authEmail"
)

func AuthMiddleware(tokenService *auth.TokenService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				httputil.Error(w, http.StatusUnauthorized, "Missing Authorization header")
				return
			}

			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				httputil.Error(w, http.StatusUnauthorized, "Invalid Authorization header format. Expected 'Bearer <token>'")
				return
			}

			claims, err := tokenService.ValidateToken(parts[1])
			if err != nil {
				httputil.Error(w, http.StatusUnauthorized, "Invalid or expired token")
				return
			}

			ctx := context.WithValue(r.Context(), UserContextKey, claims.UserID)
			ctx = context.WithValue(ctx, EmailContextKey, claims.Email)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func GetUserIDFromContext(ctx context.Context) (uuid.UUID, bool) {
	val, ok := ctx.Value(UserContextKey).(uuid.UUID)
	return val, ok
}

func GetEmailFromContext(ctx context.Context) (string, bool) {
	val, ok := ctx.Value(EmailContextKey).(string)
	return val, ok
}
