cap program drop mcp_connect
program mcp_connect
    version 17.0
    syntax [, RESET SHUTDOWN BRIDGEPORT(integer 8080) DRONEPORT(integer 8001)]

    if "`shutdown'" != "" {
        di as text "[Drone] Shutdown 요청..."
        javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        exit
    }

    if "`reset'" != "" {
        di as text "[Drone] Reset: 종료 후 재시작..."
        capture javacall com.stata_mcp.drone.StataDrone stop, jars(stata-drone.jar)
        sleep 1000
    }

    di as text "[Drone] Java Stata-MCP-Drone 시작..."
    javacall com.stata_mcp.drone.StataDrone start, ///
        args("`bridgeport'" "`droneport'") jars(stata-drone.jar)

end
