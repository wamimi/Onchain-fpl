import { BigInt } from "@graphprotocol/graph-ts"
import {
  ParticipantJoined as ParticipantJoinedEvent,
  FPLIdRegistered as FPLIdRegisteredEvent,
  ScoresUpdated as ScoresUpdatedEvent
} from "../generated/templates/League/League"
import { League, Participant } from "../generated/schema"

export function handleParticipantJoined(event: ParticipantJoinedEvent): void {
  let leagueAddress = event.address
  let participantAddress = event.params.participant

  // Create unique ID: leagueAddress-participantAddress
  let participantId = leagueAddress.toHexString() + "-" + participantAddress.toHexString()

  let participant = new Participant(participantId)
  participant.league = leagueAddress
  participant.address = participantAddress
  participant.fplId = BigInt.fromI32(0) // Not registered yet
  participant.score = BigInt.fromI32(0) // No score yet
  participant.rank = BigInt.fromI32(0) // Not ranked yet
  participant.claimableWinnings = BigInt.fromI32(0)
  participant.hasClaimed = false
  participant.joinedAt = event.block.timestamp

  participant.save()
}

export function handleFPLIdRegistered(event: FPLIdRegisteredEvent): void {
  let leagueAddress = event.address
  let participantAddress = event.params.participant
  let fplId = event.params.fplId

  // Create participant ID
  let participantId = leagueAddress.toHexString() + "-" + participantAddress.toHexString()

  // Load existing participant (should exist from ParticipantJoined event)
  let participant = Participant.load(participantId)

  if (participant) {
    participant.fplId = fplId
    participant.save()
  }
}

export function handleScoresUpdated(event: ScoresUpdatedEvent): void {
  let leagueAddress = event.address
  let participants = event.params.participants
  let scores = event.params.scores

  // Update scores for each participant
  for (let i = 0; i < participants.length; i++) {
    let participantAddress = participants[i]
    let score = scores[i]

    let participantId = leagueAddress.toHexString() + "-" + participantAddress.toHexString()
    let participant = Participant.load(participantId)

    if (participant) {
      participant.score = score
      participant.save()
    }
  }
}
