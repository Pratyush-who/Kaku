package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port         string
	DatabaseURL  string
	JWTSecret    string
	JWTExpiresIn time.Duration
	BcryptCost   int
}

func Load() *Config {
	port := getEnv("PORT", "8080")
	dbURL := getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/kaku?sslmode=disable")
	jwtSecret := getEnv("JWT_SECRET", "super-secret-kaku-jwt-key-change-in-production")
	jwtExpiresHours := getEnvAsInt("JWT_EXPIRES_HOURS", 72)
	bcryptCost := getEnvAsInt("BCRYPT_COST", 12)

	return &Config{
		Port:         port,
		DatabaseURL:  dbURL,
		JWTSecret:    jwtSecret,
		JWTExpiresIn: time.Duration(jwtExpiresHours) * time.Hour,
		BcryptCost:   bcryptCost,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getEnvAsInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if intVal, err := strconv.Atoi(val); err == nil {
			return intVal
		}
	}
	return defaultVal
}
