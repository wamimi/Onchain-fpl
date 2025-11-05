import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { LeagueCreated } from "../generated/schema"
import { LeagueCreated as LeagueCreatedEvent } from "../generated/LeagueFactory/LeagueFactory"
import { handleLeagueCreated } from "../src/league-factory"
import { createLeagueCreatedEvent } from "./league-factory-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let leagueAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let creator = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let name = "Example string value"
    let entryFee = BigInt.fromI32(234)
    let duration = BigInt.fromI32(234)
    let timestamp = BigInt.fromI32(234)
    let newLeagueCreatedEvent = createLeagueCreatedEvent(
      leagueAddress,
      creator,
      name,
      entryFee,
      duration,
      timestamp
    )
    handleLeagueCreated(newLeagueCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("LeagueCreated created and stored", () => {
    assert.entityCount("LeagueCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "leagueAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "creator",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "name",
      "Example string value"
    )
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "entryFee",
      "234"
    )
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "duration",
      "234"
    )
    assert.fieldEquals(
      "LeagueCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "timestamp",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
