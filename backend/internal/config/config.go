package config

import (
	"bufio"
	"log"
	"os"
	"strconv"
	"strings"
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
	loadDotEnv()

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

// loadDotEnv searches candidate paths for .env and sets environment variables if not already present
func loadDotEnv() {
	candidates := []string{".env", "../.env", "backend/.env"}
	for _, path := range candidates {
		file, err := os.Open(path)
		if err != nil {
			continue
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line == "" || strings.HasPrefix(line, "#") {
				continue
			}
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				val := strings.TrimSpace(parts[1])
				// Strip surrounding quotes if present
				if (strings.HasPrefix(val, "\"") && strings.HasSuffix(val, "\"")) ||
					(strings.HasPrefix(val, "'") && strings.HasSuffix(val, "'")) {
					val = val[1 : len(val)-1]
				}
				if os.Getenv(key) == "" {
					_ = os.Setenv(key, val)
				}
			}
		}
		log.Printf("Loaded environment configuration from %s", path)
		return
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
