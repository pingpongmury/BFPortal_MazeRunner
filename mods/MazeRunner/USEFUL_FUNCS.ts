//TEAMS
    // Sets the target player's team.
    export function SetTeam(player: Player, team: Team): void;

//WORLD
    // Request the system to evaluate if a straight line between two points is interupted or not. Use OnRayCastHit and OnRayCastMissed to read the result.
    export function RayCast(player: Player, start: Vector, stop: Vector): void;

    // Request the system to evaluate if a straight line between two points is interupted or not. Use OnRayCastHit and OnRayCastMissed to read the result.
    export function RayCast(start: Vector, stop: Vector): void;

//DAMAGE
    // Deals a provided amount of damage to a target player. Can optionally specify damage giver..
    export function DealDamage(player: Player, damageAmount: number): void;

    // Deals a provided amount of damage to a target player. Can optionally specify damage giver..
    export function DealDamage(player: Player, damageAmount: number, damageGiver: Player): void;

    // Deals a provided amount of damage to a target player. Can optionally specify damage giver..
    export function DealDamage(vehicle: Vehicle, damageAmount: number): void;

    // Kills a target player (skips the Mandown state).
    export function Kill(player: Player): void;

    // Kills a target player (skips the Mandown state).
    export function Kill(vehicle: Vehicle): void;