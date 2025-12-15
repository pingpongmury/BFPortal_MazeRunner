//Global Tick Rate
const GLOBAL_TICK_RATE: number = 10//0.034; //in seconds (~30 ticks per second)

//MAZE WALLS
//const MAZE_WALL_DIMENSIONS = {width: 5.106211, height: 3.115628, depth: 1.586211}; //FoundationPlanter_Long_01 Defaults
//moving wall part color: 8dffff
const MAZE_WALL_DIMENSIONS = {width: 5.106211, height: 3.0, depth: 1.586211}; //FoundationPlanter_Long_01

//Phase Open/Close Speeds (in seconds) *MUST BE LESS THAN CORRESPONDING PHASE TIME*
const MAZE_WALL_PHASE_MOVE_SPEEDS : number[] = [0.5,1,5,10]; //Phase A, B, C, D

//Phase Cycle Times (in seconds)
const MAZE_WALL_PHASE_PERIOD : number[] = [5,3,10,30]; //Phase A, B, C, D

//Phase Walls ObjIds
const MAZE_PHASE_A_WALL_IDS : number[] = [1001001,1001002];
const MAZE_PHASE_B_WALL_IDS : number[] = [2110001];
const MAZE_PHASE_C_WALL_IDS : number[] = [3100001];
const MAZE_PHASE_D_WALL_IDS : number[] = [];

//Phase Array
const MAZE_PHASE_IDS: number[][] = [MAZE_PHASE_A_WALL_IDS, MAZE_PHASE_B_WALL_IDS, MAZE_PHASE_C_WALL_IDS, MAZE_PHASE_D_WALL_IDS];

//SPAWNERS
//Counts for each type of spawner
const AI_SPAWNER_COUNT: number          = 4; //Number of AI Spawners
const LOOT_SPAWNER_COUNT: number        = 0; //Number of Loot Spawners
const VEHICLE_SPAWNER_COUNT: number     = 1; //Number of Vehicle Spawners
const EMPLACEMENT_SPAWNER_COUNT: number = 1; //Number of Emplacement Spawners

//Spawner ID offsets
const AI_SPAWNER_OFFSET: number          = 10; //AI Spawner IDs start at 11
const LOOT_SPAWNER_OFFSET: number        = 100; //Loot Spawner IDs start at 101
const VEHICLE_SPAWNER_OFFSET: number     = 200; //Vehicle Spawner IDs start at 201
const EMPLACEMENT_SPAWNER_OFFSET: number = 300; //Emplacement Spawner IDs start at 301

//Enemy Team
const ENEMY_TEAM: mod.Team = mod.GetTeam(2);
let enemyTeamSize: number = 0;

//Constants
const PI = mod.Pi();

class MazeWall{
    wall_id: number = -1;
    wall_obj: mod.SpatialObject | null = null;
    is_open: boolean = false;
    phase: string = "";
    height: string = "";
    moveType: string = "";
    direction: string = "";
    doorIndex: number = -1;
    compIndex: number = -1;
    openTransform: mod.Transform = mod.CreateTransform(mod.CreateVector(0,0,0), mod.CreateVector(0,0,0));
    closeTransform: mod.Transform = mod.CreateTransform(mod.CreateVector(0,0,0), mod.CreateVector(0,0,0));

    constructor(wallId: number){
        this.wall_id = wallId;
        this.wall_obj = mod.GetSpatialObject(wallId)
        let initPos: mod.Vector = mod.GetObjectPosition(this.wall_obj);
        let initRot: mod.Vector = mod.GetObjectRotation(this.wall_obj);
        this.closeTransform = mod.CreateTransform(initPos, initRot);       
        this.parseDoorId(wallId);
        this.calculateMovementVectors(initPos, initRot);
    }

    parseDoorId(objId: number) {
    //Door Numbering Scheme:
    //   {Phase}         {Height}          {Movement Type}              {Direction}          {doorIndex} {doorIndex}  {compIndex}
    //{1:A,2:B,etc.}  {0:Full,1:Half}  {0:Linear,1:Rotational}  {0:UP,1:DOWN,2:LEFT,3:RIGHT}    {0-9}       {0-9}        {1-9}
    //Example:
    //ObjId = 1103172 would correspond to a HALF-height door in PHASE A that moves LINEARLY to the RIGHT and is the 17TH of that type in phase A with components enumerated with compIndex (in this case component 2)

    // Extract digits by position
    const phaseCode      = Math.floor(objId / 1000000);
    const heightCode     = Math.floor((objId % 1000000) / 100000);
    const movementCode   = Math.floor((objId % 100000) / 10000);
    const directionCode  = Math.floor((objId % 10000) / 1000);
    this.doorIndex       = Math.floor((objId % 1000)/10);
    this.compIndex       = objId % 10;

    // Map phase
    const phaseMap: Record<number, string> = {
        1: "A",
        2: "B",
        3: "C",
        4: "D"
    };
    this.phase = phaseMap[phaseCode] ?? "?";

    // Map height
    const heightMap: Record<number, string> = {
        0: "Full",
        1: "Half"
    };
    this.height = heightMap[heightCode] ?? "?";

    // Map movement
    const movementMap: Record<number, string> = {
        0: "Linear",
        1: "Rotational"
    };
    this.moveType = movementMap[movementCode] ?? "?";

    // Map direction
    let directionMap: Record<number, string> = {};
    if(this.moveType === "Linear"){
        directionMap = {
            0: "Up",
            1: "Down",
            2: "Left",
            3: "Right"
        };
    }else if(this.moveType === "Rotational"){
        directionMap  = {
            0: "CW",
            1: "CCW",
            2: "Up",
            3: "Down"
        };
    }
    this.direction = directionMap[directionCode] ?? "?";

    if(this.phase === "?" || this.height === "?" || this.moveType === "?" || this.direction === "?"){
        mod.SendErrorReport(mod.Message(mod.stringkeys.ERR_PARSE_FAIL, objId));
    }
    }

    calculateMovementVectors(initPos: mod.Vector, initRot: mod.Vector){
        mod.SendErrorReport(mod.Message(mod.YComponentOf(initRot)));
        mod.SendErrorReport(mod.Message(mod.YComponentOf(initRot) / (PI/2)));
        mod.SendErrorReport(mod.Message(mod.RoundToInteger(mod.YComponentOf(initRot) /  (PI/2))));
        if(this.moveType === "Linear"){
            switch(this.direction){
                case "Up":
                    //move up
                    if (this.height === "Full") {
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos) + 2 * MAZE_WALL_DIMENSIONS.height, mod.ZComponentOf(initPos)), initRot);
                    }else if(this.height === "Half"){
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos) + MAZE_WALL_DIMENSIONS.height, mod.ZComponentOf(initPos)), initRot);
                    }
                    break;
                case "Down":
                    //move down
                    if (this.height === "Full") {
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos) - 2 * MAZE_WALL_DIMENSIONS.height, mod.ZComponentOf(initPos)), initRot);
                    }else if(this.height === "Half"){
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos) - MAZE_WALL_DIMENSIONS.height, mod.ZComponentOf(initPos)), initRot);
                    }
                    break;
                case "Left":
                    //move left
                    if(mod.RoundToInteger(mod.YComponentOf(initRot) /  (PI/2)) == 0 || mod.RoundToInteger(mod.YComponentOf(initRot) /  (PI/2)) == 2){ //Object is aligned along X axis
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos) - MAZE_WALL_DIMENSIONS.width, mod.YComponentOf(initPos), mod.ZComponentOf(initPos)), initRot);
                    }else{  //Object is aligned along Z axis                                                                                          //Object is aligned along Z axis
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos), mod.ZComponentOf(initPos) - MAZE_WALL_DIMENSIONS.width), initRot);
                    }
                    break;
                case "Right":
                    //move right
                    if(mod.RoundToInteger(mod.YComponentOf(initRot) /  (PI/2)) == 0 || mod.RoundToInteger(mod.YComponentOf(initRot) /  (PI/2)) == 2){ //Object is aligned along X axis
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos) + MAZE_WALL_DIMENSIONS.width, mod.YComponentOf(initPos), mod.ZComponentOf(initPos)), initRot);
                    }else{  //Object is aligned along Z axis                                                                                          //Object is aligned along Z axis
                        this.openTransform = mod.CreateTransform(mod.CreateVector(mod.XComponentOf(initPos), mod.YComponentOf(initPos), mod.ZComponentOf(initPos) + MAZE_WALL_DIMENSIONS.width), initRot);
                    }
                    break;
                default:
                    break;
            }
        }else if(this.moveType === "Rotational"){
            switch(this.direction){
                case "CW":
                    //rotate Clockwise about vertical axis
                    this.openTransform = mod.CreateTransform(initPos, mod.CreateVector(mod.XComponentOf(initRot), mod.YComponentOf(initRot) + mod.DegreesToRadians(90), mod.ZComponentOf(initRot)));
                    break; 
                case "CCW":
                    //rotate Counter-Clockwise about vertical axis
                    this.openTransform = mod.CreateTransform(initPos, mod.CreateVector(mod.XComponentOf(initRot), mod.YComponentOf(initRot) - mod.DegreesToRadians(90), mod.ZComponentOf(initRot)));
                    break;
                case "Up":
                    //rotate Clockwise about horizontal axis
                    this.openTransform = mod.CreateTransform(initPos, mod.CreateVector(mod.XComponentOf(initRot) + mod.DegreesToRadians(90), mod.YComponentOf(initRot), mod.ZComponentOf(initRot)));
                    break;
                case "Down":
                    //rotate Counter-Clockwise about horizontal axis
                    this.openTransform = mod.CreateTransform(initPos, mod.CreateVector(mod.XComponentOf(initRot) - mod.DegreesToRadians(90), mod.YComponentOf(initRot), mod.ZComponentOf(initRot)));
                    break;
                default:
                    break;
            }
        }
    }

    cycleDoor(speed: number){
        if(this.wall_obj !== null && this.is_open === false){
            //Open Door
            let timeInSeconds = speed;
            mod.SetObjectTransformOverTime(this.wall_obj, this.openTransform, timeInSeconds, false, false);
            this.is_open = true;

        }else if(this.wall_obj !== null && this.is_open === true){
            //Close Door
            let timeInSeconds = speed;
            mod.SetObjectTransformOverTime(this.wall_obj, this.closeTransform, timeInSeconds, false, false);
            this.is_open = false;
        }
    }
}

class MazePhase{
    phase_name: string = "";
    maze_walls: MazeWall[] = [];
    phase_period: number = 0;
    phase_speed: number = 0;
    phase_timer: number = 0;
    is_open: boolean = false;

    constructor(phaseName: string, phaseT: number, speed: number, wallIds: number[]){
        this.phase_name = phaseName;
        this.phase_period = phaseT;
        this.phase_speed = speed;
        for(const id of wallIds){
            const wall = new MazeWall(id);
            this.maze_walls.push(wall);
        }
    }

    cyclePhaseWalls(){
        for(const wall of this.maze_walls){
            wall.cycleDoor(this.phase_speed);
        }
        this.is_open = !this.is_open;
    }
}

function spawnAI(): void{
    for(let i = 1; i <= AI_SPAWNER_COUNT; i++){
        mod.AISetUnspawnOnDead(mod.GetSpawner(i + AI_SPAWNER_OFFSET), true); //Despawn AI on death
        mod.SpawnAIFromAISpawner(mod.GetSpawner(i + AI_SPAWNER_OFFSET), mod.SoldierClass.Assault, ENEMY_TEAM);
        enemyTeamSize += 1;
    }
}

function respawnRandAI(): void{
    const spawnerId: number = mod.RoundToInteger(mod.RandomReal(AI_SPAWNER_OFFSET + 1, AI_SPAWNER_OFFSET + AI_SPAWNER_COUNT));
    mod.AISetUnspawnOnDead(mod.GetSpawner(spawnerId), true); //Despawn AI on death
    mod.SpawnAIFromAISpawner(mod.GetSpawner(spawnerId), mod.SoldierClass.Assault, ENEMY_TEAM);
    enemyTeamSize += 1;
}

function initializeMazePhases(): MazePhase[]{
    const mazePhases: MazePhase[] = [];
    for(let i = 0; i < MAZE_PHASE_IDS.length; i++){
        const phaseName: string = String.fromCharCode(65 + i); //Convert 0,1,2... to A,B,C...
        const phaseT: number = MAZE_WALL_PHASE_PERIOD[i];
        const speed: number = MAZE_WALL_PHASE_MOVE_SPEEDS[i];
        const wallIds: number[] = MAZE_PHASE_IDS[i];
        const phase: MazePhase = new MazePhase(phaseName, phaseT, speed, wallIds);
        mazePhases.push(phase);
    }
    return mazePhases;
}

export async function OnGameModeStarted(){
    const mazePhases: MazePhase[] = initializeMazePhases();
    mod.SendErrorReport(mod.Message(mod.stringkeys.MAZE_init, mazePhases.length));
    spawnAI();
    tickUpdate();
    mazeUpdate(mazePhases);

}

//Full speed game loop, used for spawn logic, damage, etc.
async function tickUpdate(){
    //Main Game Loop
    mod.SendErrorReport(mod.Message(mod.stringkeys.GAME_loop_started));
    while(true){
        await mod.Wait(GLOBAL_TICK_RATE);
        if(mod.CountOf(mod.AllPlayers()) < AI_SPAWNER_COUNT + 1){ //Garbage test code to respawn AI when one dies. TESTING ONLY
            respawnRandAI();
        }
        
    }
}

//Updates maze phases every second
export async function mazeUpdate(mazePhases: MazePhase[]){
    while (true){
        await mod.Wait(1);
        for(const phase of mazePhases){
            phase.phase_timer += 1;
            if(phase.phase_timer === phase.phase_period){ //If phase period reached, cycle doors
                phase.phase_timer = 0;
                phase.cyclePhaseWalls();
                if(phase.is_open){
                    mod.SendErrorReport(mod.Message(mod.stringkeys.MAZE_openPhase));
                }else{
                    mod.SendErrorReport(mod.Message(mod.stringkeys.MAZE_closePhase));
                }
            }
        }
    }
}

//export async function OnSpawnerSpawned(eventPlayer: mod.Player, eventSpawner: mod.Spawner) {}

/*Note to future self: 

    LINEAR WALLS ARE BROKEN. Need to compensate for rotated doors. If mod.YComponentOf(mod.GetObjectRotation(wallObj)) is not 0, then the door is rotated and I need to adjust the openTransform accordingly.

    I was working on getting spawners working. AISpawners are now functional, but loot, vehicle, and emplacement spawners are not yet implemented.
    See USEFUL_FUNCS.ts for relevant functions.

    Need to figure out how the spawn system is going to work in this maze runner gamemode.
    Ideas:
        - Maze paths have AISpawners that spawn enemies at GameModeStart. These enemies patrol sections of the maze. (See AIWaypointIdleBehavior(player: Player, waypointPath: WaypointPath))
            - Equipment for enemy AI gets increasingly more dangerous the further you go into the maze.
        
        - LootSpawners can be found scattered throughout the maze, giving players better equipment to deal with the enemies.
            - Equipment in LootSpawners also gets better the further you go into the maze.
            - Picking up high-tier loot from dead enemies could break this feature, so maybe disable loot drops from enemies (somehow)?
            - Can I use RedSec items? Plates would be cool. The Crate system, too.
        
        - Progression could also be metered by placing CapturePoints in the maze that players have to reach to unlock further sections of the maze.
            - I'd need to figure out how to manage AI spawning based on player events. (See OnPlayerEnterAreaTrigger, OnPlayerExitAreaTrigger, OnPlayerEnterCapturePoint, OnPlayerExitCapturePoint in USEFUL_FUNCS.ts)
            - The SDK provides all kinds of AI behavior functions, including AIBattlefieldBehavior, AIDefendPositionBehavior, AIIdleBehavior, AIMoveToBehavior, etc.
            - Would need a way to set these behaviors either in Godot or another ObjId-based system (ew).
                - Use dedicated spawners? Yeah, probably.
        
        - VehicleSpawners and EmplacementSpawners are probably not necessary for this gamemode, but could be fun easter eggs if placed in secret areas of the maze.
            - It might also be a mechanic. Once a player captures a CapturePoint, they have to defend it against a wave of enemies to unlock the door out of the CapturePoint.

        

*/