package events

import (
	"fmt"
	"log"
	"regexp"
	"time"

	jsoniter "github.com/json-iterator/go"

	"dicious/pkg/repository"
)

var (
	json                     = jsoniter.ConfigCompatibleWithStandardLibrary
	notifMatchHostAdd        = regexp.MustCompile("^baremetal.node.(create|update).end")
	notifMatchHostRem        = regexp.MustCompile("^baremetal.node.delete.end")
	notifMatchChassisAdd     = regexp.MustCompile("^baremetal.chassis.(create|update).end")
	notifMatchChassisRem     = regexp.MustCompile("^baremetal.chassis.delete.end")
	notifMatchPortAdd        = regexp.MustCompile("^baremetal.port.(create|update).end")
	notifMatchPortRem        = regexp.MustCompile("^baremetal.port.delete.end")
	notifMatchPortGroupAdd   = regexp.MustCompile("^baremetal.portgroup.(create|update).end")
	notifMatchPortGroupRem   = regexp.MustCompile("^baremetal.portgroup.delete.end")
	notifMatchMaintenanceSet = regexp.MustCompile("^baremetal.node.maintenance_set.end")
)

type Notification struct {
	Version string `json:"oslo.version"`
	Message string `json:"oslo.message"`
}

type NotificationMessage struct {
	MessageId   string              `json:"message_id"`
	PublisherId string              `json:"publisher_id"`
	EventType   string              `json:"event_type"`
	Priority    string              `json:"priority"`
	Payload     NotificationPayload `json:"payload"`
}

type NotificationPayload struct {
	Data      any    `json:"ironic_object.data"`
	Namespace string `json:"ironic_object.namespace"`
	Name      string `json:"ironic_object.name"`
	Version   string `json:"ironic_object.version"`
}

func (p *NotificationPayload) UnmarshalJSON(b []byte) error {
	var objMap map[string]*jsoniter.RawMessage
	err := json.Unmarshal(b, &objMap)
	if err != nil {
		return err
	}

	jsonType, ok := objMap["ironic_object.name"]
	if !ok {
		return fmt.Errorf("ironic_object.name attr is mandatory.")
	}

	jsonData, ok := objMap["ironic_object.data"]
	if !ok {
		return fmt.Errorf("ironic_object.data attr is mandatory.")
	}

	var goType string
	err = json.Unmarshal(*jsonType, &goType)
	if err != nil {
		return fmt.Errorf("error getting type: %s", err)
	}

	switch goType {
	case "NodeCRUDPayload":
		var nodeCRUD NodeCRUDPayload
		err = json.Unmarshal(*jsonData, &nodeCRUD)
		if err != nil {
			return err
		}
		p.Data = nodeCRUD
	default:
		return fmt.Errorf("Unknown type %s", goType)
	}
	return nil
}

type NodeCRUDPayload struct {
	ChassisUuid       string `json:"chassis_uuid"`
	Name              string `json:"name"`
	ResourceClass     string `json:"resource_class"`
	PowerState        string `json:"power_state"`
	ProvisionState string `json:"provision_state"`
	Uuid              string `json:"uuid"`
}

func handleNotification(repo *repository.SQLiteRepository, msg []byte, t time.Time) error {
	notification := &Notification{}
	message := &NotificationMessage{}
	if err := json.Unmarshal(msg, &notification); err != nil {
		return fmt.Errorf("Unable to unmarshall notification: %v", err)
	}

	if err := json.Unmarshal([]byte(notification.Message), &message); err != nil {
		return fmt.Errorf("Unable to unmarshall notification message: %v", err)
	}

	log.Printf("[DEBUG] handling message %s/%s.", message.EventType, message.MessageId)

	if notifMatchHostAdd.MatchString(message.EventType) {
		nodePayload, ok := message.Payload.Data.(NodeCRUDPayload)
		if !ok {
			return fmt.Errorf(
				"Unconsistent data in notification payload data for message %v/%v",
				message.EventType,
				message.MessageId,
			)
		}

		host := &repository.Host{
			RackId:            nodePayload.ChassisUuid,
			Name:              nodePayload.Name,
			ResourceClass:     nodePayload.ResourceClass,
			PowerState:        nodePayload.PowerState,
			ProvisionState: nodePayload.ProvisionState,
			Id:                nodePayload.Uuid,
		}

		log.Printf("[DEBUG] Adding host %s/%s.", host.Id, host.Name)
		if err := repository.Add[repository.Host](repo, host); err != nil {
			return fmt.Errorf(
				"Unable to store notification payload data in message %v/%v: %v",
				message.EventType,
				message.MessageId,
				err,
			)
		}
	}

	return nil
}
