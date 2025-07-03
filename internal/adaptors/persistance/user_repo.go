package persistance

import (
	"TimeBankProject/internal/core/serviceSession"
	"TimeBankProject/internal/core/skills"
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
	// query := "insert into users(username, email, password, work_location, balance) values($1, $2, $3, $4, $5) returning uid"
	hashPass, err := utilities.HashPassword(newUser.Password)
	if err != nil {
		fmt.Println(err, "unable to hash password")
	}
	if newUser.Balance == 0 {
		// Don't include balance - let database use default (5.0)
		query := "insert into users(username, email, password, work_location) values($1, $2, $3, $4) returning uid"
		err = u.db.db.QueryRow(query, newUser.Username, newUser.Email, hashPass, newUser.Work_location).Scan(&uid)
	} else {
		// User explicitly provided balance
		query := "insert into users(username, email, password, work_location, balance) values($1, $2, $3, $4, $5) returning uid"
		err = u.db.db.QueryRow(query, newUser.Username, newUser.Email, hashPass, newUser.Work_location, newUser.Balance).Scan(&uid)
	}
	// err = u.db.db.QueryRow(query, newUser.Username, newUser.Email, hashPass, newUser.Work_location, newUser.Balance).Scan(&uid) //scan will check the numbers of rows executed, and will assign that number to uid
	if err != nil {
		return user.User{}, err
	}
	newUser.Uid = uid
	return newUser, nil
}

func (u *UserRepo) GetUser(username string) (user.User, error) {
	var newUser user.User
	query := "select uid, username, email, balance, password from users where username = $1"
	err := u.db.db.QueryRow(query, username).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Balance, &newUser.Password)
	if err != nil {
		return user.User{}, err
	}
	return newUser, nil
}

func (u *UserRepo) GetUserByID(id int) (user.User, error) {
	var newUser user.User
	query := "select uid, username, email,work_location,balance,created_at from users where uid = $1"
	// query := "select uid, username, email, password from users where uid = $1"
	//! password not entered in above query
	err := u.db.db.QueryRow(query, id).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Work_location, &newUser.Balance, &newUser.Created_at)
	// err := u.db.db.QueryRow(query, id).Scan(&newUser.Uid, &newUser.Username, &newUser.Email, &newUser.Password)
	if err != nil {
		return user.User{}, err
	}
	return newUser, nil
}

func (u *UserRepo) CreateServiceSession(newSession serviceSession.SSession) (serviceSession.SSession, error) {
	var sessionId int
	var tempSkillID int
	var blankSession serviceSession.SSession
	// ^Check whether provided_by and Provided_to user exist, or not
	// *Use Transaction
	tx, err := u.db.db.Begin()
	if err != nil {
		return serviceSession.SSession{}, err
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()
	//check user ki skill active hai ya nahi
	var correspongingSkill skills.Skill
	correspongingSkill.User_Id = newSession.ProvidedBy

	// else {
	// 	fmt.Println("Data type of Skill Status is Wrong")	//for personal user, tbhi pta chalega ki DB ka Boolean, Go ke bool se ccompare kr pa rha hai ya nahi
	// }

	err = tx.QueryRow("select id from skills where name=$1 and user_id=$2", newSession.SkillName, newSession.ProvidedBy).Scan(&tempSkillID)
	if err != nil {
		return blankSession, fmt.Errorf("Unable to find Record in Skills Table")
	}

	err = tx.QueryRow("select status from skills where user_id=$1", correspongingSkill.User_Id).Scan(&correspongingSkill.Status)
	if err != nil {
		return blankSession, fmt.Errorf("Failed to Fetch Skill Status")
	}

	if correspongingSkill.Status == false {
		return blankSession, fmt.Errorf("Helper Skill is not active")
	}
	fmt.Println("New Session-", newSession)
	//convert duration into interval
	query := "insert into service_sessions(duration, provided_by, provided_to, skill_name) values($1,$2,$3,$4) returning id"
	err = u.db.db.QueryRow(query, newSession.Duration, newSession.ProvidedBy, newSession.ProvidedTo, newSession.SkillName).Scan(&sessionId)
	fmt.Println("Session id =",sessionId)
	if err != nil {
		return blankSession, fmt.Errorf("Unable to get New Session ID, or insert row")
	}
	err = tx.Commit()
	if err != nil {
		return blankSession, fmt.Errorf("Failed to Insert record, Unable to complete Trasaction!!!")
	}
	newSession.ServiceId = sessionId
	return newSession, nil
}

func (u *UserRepo) AddSkill(newSkill skills.Skill) (skills.Skill, error) {
	var skillID int
	query := "insert into skills(name,description,user_id,status) values($1,$2,$3,$4) returning id"
	err := u.db.db.QueryRow(query, newSkill.Name, newSkill.Description, newSkill.User_Id, newSkill.Status).Scan(&skillID)
	if err != nil {
		return skills.Skill{}, err
	}
	newSkill.Id = skillID
	return newSkill, nil
}
