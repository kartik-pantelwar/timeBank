package serviceSession

import "time"

type SSession struct {
	ServiceId  int    `json:"serviceId"`
	Duration   string `json:"duration"`
	ProvidedBy int    `json:"providedBy"`
	ProvidedTo int    `json:"providedTo"`
	SkillName  string `json:"skillName"`
	// Scheduled_at time.Time `json:"scheduled_at"`
	// Notes        string    `json:"notes"`
	Created_at time.Time `json:"created_at"`
}

type Feedback struct {
	Id          int       `json:"id"`
	Description string    `json:"description"`
	Created_at  time.Time `json:"created_at"`
	Session_id  int       `json:"session_id"`
	Rating      float64   `json:"rating"`
}

type TimeCredits struct {
	Id             int       `json:"id"`
	Given_to       int       `json:"given_to"`
	Given_by       int       `json:"given_by"`
	Amount         float64   `json:"amount"`
	Transaction_at time.Time `json:"trasaction_at"`
}
