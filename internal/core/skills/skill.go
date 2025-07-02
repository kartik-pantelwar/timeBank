package skills

type Skill struct {
	Id          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	User_Id     int    `json:"user_id"`
	Status      bool   `json:"status"`
}
