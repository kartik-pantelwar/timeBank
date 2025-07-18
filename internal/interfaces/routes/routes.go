package routes

import (
	userhandler "TimeBankProject/internal/interfaces/handler/userhandler"
	"TimeBankProject/internal/interfaces/middleware"
	"net/http"

	"github.com/go-chi/chi/v5"
)

func InitRoutes(
	userHandler *userhandler.UserHandler) http.Handler {
	router := chi.NewRouter()

	router.Route("/auth", func(r chi.Router) {
		r.Post("/register", userHandler.Register)
		r.Post("/login", userHandler.Login)
		r.Post("/refresh", userHandler.Refresh)
	})

	router.Route("/user", func(r chi.Router) {
		r.Use(middleware.Authenticate)
		r.Get("/profile", userHandler.Profile)
		r.Post("/logout", userHandler.LogOut)
		r.Post("/sessions", userHandler.CreateServiceSession)
		//duration should be in format 'hours:minutes:seconds'
		r.Post("/skill/add", userHandler.CreateSkill)
		r.Post("/session/{id}/feedback", userHandler.CreateFeedback)
	})

	return router
}
