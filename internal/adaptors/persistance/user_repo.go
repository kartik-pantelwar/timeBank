package persistance

import (
	"TimeBankProject/internal/core/serviceSession"
	user "TimeBankProject/internal/core/user"
	"TimeBankProject/pkg/utilities"
	"fmt"
	// "github.com/ydb-platform/ydb-go-sdk/v3/query"
)

type UserRepo struct {
	db *Database
}

func NewUserRepo(d *Database) UserRepo {
	return UserRepo{db: d}
}

func (u *UserRepo) CreateUser(newUser user.User) (user.User, error) {
	var uid int
	query := "insert into users(username, email, password, work_location, is_available) values($1, $2, $3, $4, $5) returning uid"
	hashPass, err := utilities.HashPassword(newUser.Password)
	if err != nil {
		fmt.Println(err, "unable to hash password")
	}
	err = u.db.db.QueryRow(query, newUser.Username, newUser.Email, hashPass, newUser.Work_location, newUser.Is_available).Scan(&uid) //scan will check the numbers of rows executed, and will assign that number to uid
	if err != nil {
		return user.User{}, err
	}
	newUser.Uid = uid
	return newUser, nil
}

func (u *UserRepo) GetUser(username string) (user.User, error) {
	var newUser user.User
	query := "select uid, username, email, balance, rating, password from users where username = $1"
	err := u.db.db.QueryRow(query, username).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Balance, &newUser.Rating, &newUser.Password)
	// query := "select uid, username, email, password from users where username = $1"
	// err := u.db.db.QueryRow(query, username).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Password)
	//! I was not entering newUser.Email in the above line
	if err != nil {
		return user.User{}, err
	}
	return newUser, nil
}

func (u *UserRepo) GetUserByID(id int) (user.User, error) {
	var newUser user.User
	query := "select uid, username, email from users where uid = $1"
	// query := "select uid, username, email, password from users where uid = $1"
	err := u.db.db.QueryRow(query, id).Scan(&newUser.Uid, &newUser.Username, &newUser.Email)
	// err := u.db.db.QueryRow(query, id).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Password)
	if err != nil {
		return user.User{}, err
	}
	return newUser, nil
}

func (u *UserRepo) CreateServiceSession(newSession serviceSession.SSession) (serviceSession.SSession, error) {
	var sessionId int
	query := "insert into service_sessions(duration, provided_by, provided_to, skill_id) values($1,$2,$3,$4)"
	err := u.db.db.QueryRow(query, newSession.Duration, newSession.ProvidedBy, newSession.ProvidedTo, newSession.SkillId).Scan(&sessionId)
	if err!=nil{
		return serviceSession.SSession{},err
	}
	newSession.ServiceId = sessionId
	return newSession,nil
}
