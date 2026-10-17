package auth

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidToken = errors.New("invalid or expired token")
)

type Claims struct {
	UserID uuid.UUID `json:"sub"`
	Email  string    `json:"email"`
	jwt.RegisteredClaims
}

type TokenService struct {
	secret    []byte
	expiresIn time.Duration
}

func NewTokenService(secret string, expiresIn time.Duration) *TokenService {
	return &TokenService{
		secret:    []byte(secret),
		expiresIn: expiresIn,
	}
}

// GenerateToken generates a signed JWT for the authenticated user
func (s *TokenService) GenerateToken(userID uuid.UUID, email string) (string, time.Time, error) {
	expiresAt := time.Now().Add(s.expiresIn)
	claims := Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "kaku-api",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString(s.secret)
	if err != nil {
		return "", time.Time{}, err
	}
	return tokenStr, expiresAt, nil
}

// ValidateToken verifies and parses the JWT token
func (s *TokenService) ValidateToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return s.secret, nil
	})

	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok {
		return nil, ErrInvalidToken
	}

	return claims, nil
}

// HashPassword creates a bcrypt hash of a plain password
func HashPassword(password string, cost int) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), cost)
	return string(bytes), err
}

// CheckPassword verifies a plaintext password against a bcrypt hash
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// HashToken hashes tokens (e.g. for invitations) using SHA-256
func HashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}
