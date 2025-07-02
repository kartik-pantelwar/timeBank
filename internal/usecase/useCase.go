package userservice

import (
	"TimeBankProject/internal/adaptors/persistance"
	"TimeBankProject/internal/core/serviceSession"
	"TimeBankProject/internal/core/session"
	"TimeBankProject/internal/core/skills"
	"TimeBankProject/internal/core/user"
	"TimeBankProject/pkg/utilities"
	"fmt"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	userRepo    persistance.UserRepo
	sessionRepo persistance.SessionRepo
}

func NewUserService(userRepo persistance.UserRepo, sessionRepo persistance.SessionRepo) UserService {
	return UserService{userRepo: userRepo, sessionRepo: sessionRepo}
}

// registration function definition
func (u *UserService) RegisterUser(user user.User) (user.User, error) {
	//^ checking if user is already registered
	newUser, err := u.userRepo.CreateUser(user)
	return newUser, err
}

type LoginResponse struct {
	FounUser    user.User
	TokenString string
	TokenExpire time.Time
	Session     session.Session
}

func (u *UserService) LoginUser(requestUser user.User) (LoginResponse, error) {
	loginResponse := LoginResponse{}

	foundUser, err := u.userRepo.GetUser(requestUser.Username)
	if err != nil {
		return loginResponse, fmt.Errorf("invalid username")
	}

	loginResponse.FounUser = foundUser
	if err := matchPassword(foundUser, requestUser.Password); err != nil {
		return loginResponse, fmt.Errorf("invalid password")
	}
	tokenString, tokenExpire, err := utilities.GenerateJWT(foundUser.Uid)
	loginResponse.TokenString = tokenString
	loginResponse.TokenExpire = tokenExpire

	if err != nil {
		return loginResponse, fmt.Errorf("failed to generate jwt")
	}

	session, err := utilities.GenerateSession(foundUser.Uid)
	loginResponse.Session = session
	if err != nil {
		return loginResponse, fmt.Errorf("failed to generate session")
	}

	err = u.sessionRepo.CreateSession(session)
	if err != nil {
		return loginResponse, fmt.Errorf("failed to create session")
	}

	return loginResponse, nil
}

func (u *UserService) GetJwtFromSession(sess string) (string, time.Time, error) {
	var tokenString string
	var tokenExpire time.Time
	session, err := u.sessionRepo.GetSession(sess)
	if err != nil {
		return tokenString, tokenExpire, err
	}

	err = matchSessionToken(sess, session.TokenHash)
	if err != nil {
		return tokenString, tokenExpire, err
	}

	tokenString, tokenExpire, err = utilities.GenerateJWT(session.Uid)
	if err != nil {
		return tokenString, tokenExpire, err
	}

	return tokenString, tokenExpire, nil
}

func (u *UserService) GetUserByID(id int) (user.User, error) {
	newUser, err := u.userRepo.GetUserByID(id)
	return newUser, err
}

func (u *UserService) LogoutUser(id int) error {
	err := u.sessionRepo.DeleteSession(id)
	return err
}

func matchPassword(user user.User, password string) error {
	err := utilities.CheckPassword(user.Password, password)
	if err != nil {
		return fmt.Errorf("unable to match password: %w", err)
	}

	return nil
}

func matchSessionToken(id string, tokenHash string) error {
	err := bcrypt.CompareHashAndPassword([]byte(tokenHash), []byte(id))
	if err != nil {
		fmt.Println(err, "Unable to Match Password")
	}
	return nil
}

func (u *UserService) CreateServiceSession(s serviceSession.SSession) (serviceSession.SSession, error) {
	newSession, err := u.userRepo.CreateServiceSession(s)
	if err!=nil{
		return s,err
	}
	return newSession, nil
}

func (u *UserService) CreateNewSkill(s skills.Skill) (skills.Skill, error){
	newSkill,err:= u.userRepo.AddSkill(s)
	if err!=nil{
		return s,err
	}
	return newSkill,nil
}