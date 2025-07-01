package serviceSession

import "time"

type SSession struct {
	ServiceId    int       `json:"serviceId"`
	Duration     float64   `json:"duration"`
	ProvidedBy   int       `json:"providedBy"`
	ProvidedTo   int       `json:"providedTo"`
	SkillId      int       `json:"skillId"`
	Scheduled_at time.Time `json:"scheduled_at"`
	Notes        string    `json:"notes"`
	Created_at   time.Time `json:"created_at"`
}
