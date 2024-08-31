-- This script creates a new database and creates the tables and stored procedures in it.

CREATE DATABASE GraphAlgorithms
GO

USE GraphAlgorithms
GO

CREATE TABLE dbo.Node
( 
    Id int NOT NULL PRIMARY KEY, 
    Name varchar(50) NULL
)
GO

CREATE TABLE dbo.Edge
(
    FromNode int NOT NULL REFERENCES dbo.Node (Id), 
    ToNode int NOT NULL REFERENCES dbo.Node (Id), 
    [Weight] decimal (10, 3) NULL,
    PRIMARY KEY CLUSTERED (FromNode ASC, ToNode ASC)
)
GO

-- Runs breadth-first search from a specific node.
-- @StartNode: If of node to start the search at.
-- @EndNode: Stop the search when node with this id is found. Specify NULL
--			 to traverse the whole graph.
CREATE PROCEDURE dbo.usp_Breadth_First (@StartNode int, @EndNode int = NULL)
AS
BEGIN
    -- Automatically rollback the transaction if something goes wrong.    
    SET XACT_ABORT ON    
    BEGIN TRAN
    
	-- Increase performance and do not intefere with the results.
    SET NOCOUNT ON;

    -- Create a temporary table for storing the discovered nodes as the algorithm runs
	CREATE TABLE #Discovered
	(
		Id int NOT NULL PRIMARY KEY,    -- The Node Id
		Predecessor int NULL,    -- The node we came from to get to this node.
		OrderDiscovered int -- The order in which the nodes were discovered.
	)

    -- Initially, only the start node is discovered.
    INSERT INTO #Discovered (Id, Predecessor, OrderDiscovered)
    VALUES (@StartNode, NULL, 0)

	-- Add all nodes that we can get to from the current set of nodes,
	-- that are not already discovered. Run until no more nodes are discovered.
	WHILE @@ROWCOUNT > 0
    BEGIN
		-- If we have found the node we were looking for, abort now.
		IF @EndNode IS NOT NULL
			IF EXISTS (SELECT TOP 1 1 FROM #Discovered WHERE Id = @EndNode)
				BREAK    
    
		-- We need to group by ToNode and select one FromNode since multiple
		-- edges could lead us to new same node, and we only want to insert it once.
		INSERT INTO #Discovered (Id, Predecessor, OrderDiscovered)
		SELECT e.ToNode, MIN(e.FromNode), MIN(d.OrderDiscovered) + 1
		FROM #Discovered d JOIN dbo.Edge e ON d.Id = e.FromNode
		WHERE e.ToNode NOT IN (SELECT Id From #Discovered)
		GROUP BY e.ToNode
    END;
    
	-- Select the results. We use a recursive common table expression to
	-- get the full path from the start node to the current node.
	WITH BacktraceCTE(Id, Name, OrderDiscovered, Path, NamePath)
	AS
	(
		-- Anchor/base member of the recursion, this selects the start node.
		SELECT n.Id, n.Name, d.OrderDiscovered, CAST(n.Id AS varchar(MAX)),
			CAST(n.Name AS varchar(MAX))
		FROM #Discovered d JOIN dbo.Node n ON d.Id = n.Id
		WHERE d.Id = @StartNode
		
		UNION ALL
		
		-- Recursive member, select all the nodes which have the previous
		-- one as their predecessor. Concat the paths together.
		SELECT n.Id, n.Name, d.OrderDiscovered,
			CAST(cte.Path + ',' + CAST(n.Id as varchar(10)) as varchar(MAX)),
			cte.NamePath + ',' + n.Name
		FROM #Discovered d JOIN BacktraceCTE cte ON d.Predecessor = cte.Id
		JOIN dbo.Node n ON d.Id = n.Id
	)
	
	SELECT Id, Name, OrderDiscovered, Path, NamePath FROM BacktraceCTE
	WHERE Id = @EndNode OR @EndNode IS NULL -- This kind of where clause can potentially produce
	ORDER BY OrderDiscovered				-- a bad execution plan, but I use it for simplicity here.
    
    DROP TABLE #Discovered
    COMMIT TRAN
    RETURN 0
END
GO

-- Runs Dijkstra's algorithm from the specified node.
-- @StartNode: Id of node to start from.
-- @EndNode: Stop the search when the shortest path to this node is found.
--			 Specify NULL find shortest path to all nodes.
CREATE PROCEDURE dbo.usp_Dijkstra (@StartNode int, @EndNode int = NULL)
AS
BEGIN
    -- Automatically rollback the transaction if something goes wrong.    
    SET XACT_ABORT ON    
    BEGIN TRAN
    
	-- Increase performance and do not intefere with the results.
    SET NOCOUNT ON;

    -- Create a temporary table for storing the estimates as the algorithm runs
	CREATE TABLE #Nodes
	(
		Id int NOT NULL PRIMARY KEY,    -- The Node Id
		Estimate decimal(10,3) NOT NULL,    -- What is the distance to this node, so far?
		Predecessor int NULL,    -- The node we came from to get to this node with this distance.
		Done bit NOT NULL        -- Are we done with this node yet (is the estimate the final distance)?
	)

    -- Fill the temporary table with initial data
    INSERT INTO #Nodes (Id, Estimate, Predecessor, Done)
    SELECT Id, 9999999.999, NULL, 0 FROM dbo.Node
    
    -- Set the estimate for the node we start in to be 0.
    UPDATE #Nodes SET Estimate = 0 WHERE Id = @StartNode
    IF @@rowcount <> 1
    BEGIN
        DROP TABLE #Nodes
        RAISERROR ('Could not set start node', 11, 1) 
        ROLLBACK TRAN        
        RETURN 1
    END

    DECLARE @FromNode int, @CurrentEstimate int

    -- Run the algorithm until we decide that we are finished
    WHILE 1 = 1
    BEGIN
        -- Reset the variable, so we can detect getting no records in the next step.
        SELECT @FromNode = NULL

        -- Select the Id and current estimate for a node not done, with the lowest estimate.
        SELECT TOP 1 @FromNode = Id, @CurrentEstimate = Estimate
        FROM #Nodes WHERE Done = 0 AND Estimate < 9999999.999
        ORDER BY Estimate
        
        -- Stop if we have no more unvisited, reachable nodes.
        IF @FromNode IS NULL OR @FromNode = @EndNode BREAK

        -- We are now done with this node.
        UPDATE #Nodes SET Done = 1 WHERE Id = @FromNode

        -- Update the estimates to all neighbour node of this one (all the nodes
        -- there are edges to from this node). Only update the estimate if the new
        -- proposal (to go via the current node) is better (lower).
        UPDATE #Nodes
		SET Estimate = @CurrentEstimate + e.Weight, Predecessor = @FromNode
        FROM #Nodes n INNER JOIN dbo.Edge e ON n.Id = e.ToNode
        WHERE Done = 0 AND e.FromNode = @FromNode AND (@CurrentEstimate + e.Weight) < n.Estimate
        
    END;
    
	-- Select the results. We use a recursive common table expression to
	-- get the full path from the start node to the current node.
	WITH BacktraceCTE(Id, Name, Distance, Path, NamePath)
	AS
	(
		-- Anchor/base member of the recursion, this selects the start node.
		SELECT n.Id, node.Name, n.Estimate, CAST(n.Id AS varchar(8000)),
			CAST(node.Name AS varchar(8000))
		FROM #Nodes n JOIN dbo.Node node ON n.Id = node.Id
		WHERE n.Id = @StartNode
		
		UNION ALL
		
		-- Recursive member, select all the nodes which have the previous
		-- one as their predecessor. Concat the paths together.
		SELECT n.Id, node.Name, n.Estimate,
			CAST(cte.Path + ',' + CAST(n.Id as varchar(10)) as varchar(8000)),
			CAST(cte.NamePath + ',' + node.Name AS varchar(8000))
		FROM #Nodes n JOIN BacktraceCTE cte ON n.Predecessor = cte.Id
		JOIN dbo.Node node ON n.Id = node.Id
	)
	SELECT Id, Name, Distance, Path, NamePath FROM BacktraceCTE
	WHERE Id = @EndNode OR @EndNode IS NULL -- This kind of where clause can potentially produce
	ORDER BY Id								-- a bad execution plan, but I use it for simplicity here.
    
    DROP TABLE #Nodes
    COMMIT TRAN
    RETURN 0
END 
GO 

-- Determines a topological ordering or reports that the graph is not a DAG.
CREATE PROCEDURE dbo.usp_TopologicalSort
AS
BEGIN
	-- Automatically rollback the transaction if something goes wrong.     
	SET XACT_ABORT ON    
	BEGIN TRAN
	
	-- Increase performance and do not intefere with the results. 
	SET NOCOUNT ON;	
	
	-- Create a temporary table for building the topological ordering
	CREATE TABLE #Order
	(
		NodeId int PRIMARY KEY,	-- The Node Id
		Ordinal int NULL		-- Defines the topological ordering. NULL for nodes that are
	)							-- not yet processed. Will be set as nodes are processed in topological order.
	
	-- Create a temporary copy of the edges in the graph that we can work on.
	CREATE TABLE #TempEdges
	(
		FromNode int,	-- From Node Id
		ToNode int,		-- To Node Id
		PRIMARY KEY (FromNode, ToNode)
	)

	-- Grab a copy of all the edges in the graph, as we will
	-- be deleting edges as the algorithm runs.
	INSERT INTO #TempEdges (FromNode, ToNode)
	SELECT e.FromNode, e.ToNode
	FROM dbo.Edge e

	-- Start by inserting all the nodes that have no incoming edges, is it
	-- is guaranteed that no other nodes should come before them in the ordering.
	-- Insert with NULL for Ordinal, as we will set this when we process the node.
	INSERT INTO #Order (NodeId, Ordinal)
	SELECT n.Id, NULL
	FROM dbo.Node n
	WHERE NOT EXISTS (
		SELECT TOP 1 1 FROM dbo.Edge e WHERE e.ToNode = n.Id)

	DECLARE @CurrentNode int,	-- The current node being processed.
			@Counter int = 0	-- Counter to assign values to the Ordinal column.

	-- Loop until we are done.
	WHILE 1 = 1
	BEGIN
		-- Reset the variable, so we can detect getting no records in the next step.
		SET @CurrentNode = NULL

		-- Select the id of any node with Ordinal IS NULL that is currently in our
		-- Order table, as all nodes with Ordinal IS NULL in this table has either
		-- no incoming edges or any nodes with edges to it have already been processed.
		SELECT TOP 1 @CurrentNode = NodeId
		FROM #Order WHERE Ordinal IS NULL
		
		-- If there are no more such nodes, we are done
		IF @CurrentNode IS NULL BREAK
		
		-- We are processing this node, so set the Ordinal column of this node to the
		-- counter value and increase the counter.
		UPDATE #Order SET Ordinal = @Counter, @Counter = @Counter + 1
		WHERE NodeId = @CurrentNode
		
		-- This is the complex part. Select all nodes that has exactly ONE incoming
		-- edge - the edge from @CurrentNode. Those nodes can follow @CurrentNode
		-- in the topological ordering because the must not come after any other nodes,
		-- or those nodes have already been processed and inserted earlier in the
		-- ordering and had their outgoing edges removed in the next step.
		INSERT #Order (NodeId, Ordinal)
		SELECT Id, NULL
		FROM dbo.Node n
		JOIN #TempEdges e1 ON n.Id = e1.ToNode	-- Join on edge destination
		WHERE e1.FromNode = @CurrentNode AND	-- Edge starts in @CurrentNode
			NOT EXISTS (							-- Make sure there are no edges to this node
				SELECT TOP 1 1 FROM #TempEdges e2	-- other then the one from @CurrentNode.
				WHERE e2.ToNode = n.Id AND e2.FromNode <> @CurrentNode)
		
		-- Last step. We are done with @CurrentNode, so remove all outgoing edges from it.
		-- This will "free up" any nodes it has edges into to be inserted into the topological ordering.
		DELETE FROM #TempEdges WHERE FromNode = @CurrentNode
	END

	-- If there are edges left in our graph after the algorithm is done, it
	-- means that it could not reach all nodes to eliminate all edges, which
	-- means that the graph must have cycles and no topological ordering can be produced.
	IF EXISTS (SELECT TOP 1 1 FROM #TempEdges)
	BEGIN
		SELECT 'The graph contains cycles and no topological ordering can
				be produced. This is the set of edges I could not remove:'
		SELECT FromNode, ToNode FROM #TempEdges
	END
	ELSE
		-- Select the nodes ordered by the topological ordering we produced.
		SELECT n.Id, n.Name
		FROM dbo.Node n
		JOIN #Order o ON n.Id = o.NodeId
		ORDER BY o.Ordinal

	-- Clean up, commit and return.
	DROP TABLE #TempEdges
	DROP TABLE #Order
	COMMIT TRAN
	RETURN 0
END
GO

-- Computes a minimum spanning tree using Prim's algorithm.
CREATE PROCEDURE dbo.usp_Prim
AS
BEGIN
    -- Automatically rollback the transaction if something goes wrong.
    SET XACT_ABORT ON    
    BEGIN TRAN
    
	-- Increase performance and don't intefere with the results.
    SET NOCOUNT ON;

    -- Create a temporary table for storing the estimates as the algorithm runs
	CREATE TABLE #Nodes
	(
		Id int NOT NULL PRIMARY KEY,    -- The Node Id
		Estimate decimal(10,3) NOT NULL,    -- What is the distance to this node, so far?
		Predecessor int NULL,    -- The node we came from to get to this node with this distance.
		Done bit NOT NULL        -- Are we done with this node yet (is the estimate the final distance)?
	)

    -- Fill the temporary table with initial data
    INSERT INTO #Nodes (Id, Estimate, Predecessor, Done)
    SELECT Id, 9999999.999, NULL, 0 FROM dbo.Node
    
    -- Set the estimate for start node to be 0.
    UPDATE TOP (1) #Nodes SET Estimate = 0

    DECLARE @FromNode int

    -- Run the algorithm until we decide that we are finished
    WHILE 1 = 1
    BEGIN
        -- Reset the variable, so we can detect getting no records in the next step.
        SELECT @FromNode = NULL

        -- Select the Id for a node not done, with the lowest estimate.
        SELECT TOP 1 @FromNode = Id
        FROM #Nodes WHERE Done = 0 AND Estimate < 9999999.999
        ORDER BY Estimate
        
        -- Stop if we have no more unvisited, reachable nodes.
        IF @FromNode IS NULL BREAK

        -- We are now done with this node.
        UPDATE #Nodes SET Done = 1 WHERE Id = @FromNode

        -- Update the estimates to all neighbour nodes of this one (all the nodes
        -- there are edges to from this node). Only update the estimate if the new
        -- proposal (to go via the current node) is better (lower).
        UPDATE #Nodes
		SET Estimate = e.Weight, Predecessor = @FromNode
        FROM #Nodes n INNER JOIN dbo.Edge e ON n.Id = e.ToNode
        WHERE Done = 0 AND e.FromNode = @FromNode AND e.Weight < n.Estimate
        
    END
   
	-- Verify that we have enough edges to connect the whole graph.
	IF EXISTS (SELECT TOP 1 1 FROM #Nodes WHERE Done = 0)
	BEGIN
		DROP TABLE #Nodes
		RAISERROR('Error: The graph is not connected.', 1, 1)
		ROLLBACK TRAN
		RETURN 1
	END
	
    -- Select the results. WHERE Predecessor IS NOT NULL filters away
    -- the one row with represents the starting node.
    SELECT n.Predecessor AS FromNode, n.Id AS ToNode,
		node1.Name AS FromName, node2.Name AS ToName
	FROM #Nodes n
	JOIN dbo.Node node1 ON n.Predecessor = node1.Id
	JOIN dbo.Node node2 ON n.Id = node2.id
	WHERE n.Predecessor IS NOT NULL
	ORDER BY n.Predecessor, n.id

	DROP TABLE #Nodes
    COMMIT TRAN
    RETURN 0
END
GO

-- Computes a minimum spanning tree using Kruskal's algorithm.
CREATE PROCEDURE dbo.usp_Kruskal
AS
BEGIN
    -- Automatically rollback the transaction if something goes wrong.    
    SET XACT_ABORT ON    
    BEGIN TRAN
    
	-- Increase performance and do not intefere with the results.
	SET NOCOUNT ON

	CREATE TABLE #MSTNodes(Id int PRIMARY KEY, ClusterNum int) -- Temp table for clusters
	CREATE TABLE #MST (FromNode int, ToNode int PRIMARY KEY (FromNode, ToNode)) -- Result accumulator
	DECLARE @FromNode int, @ToNode int,		-- Start and end point for the current edge
			@EdgeCount int = 0, @NodeCount int,	-- Edge count along the way, total node count
			@FromCluster int, @ToCluster int	-- Start and end cluster for the current edge
	
	-- First, create one cluster for each of the nodes
	INSERT #MSTNodes (Id, ClusterNum)	
	SELECT Id, Id FROM dbo.Node

	-- Get the total node count
	SELECT @NodeCount = COUNT(*) FROM #MSTNodes
	
	-- Get a cursor iterating through all the edges sorted increasing on weight.
	DECLARE EdgeCursor CURSOR READ_ONLY FOR	
		SELECT FromNode, ToNode
		FROM dbo.Edge
		WHERE FromNode < ToNode	-- Don't get self loops, they are not part of the tree.
		ORDER BY Weight
	OPEN EdgeCursor

	-- Get the first edge
	FETCH NEXT FROM EdgeCursor INTO @FromNode, @ToNode	

	-- Loop until we have no more edges or we have Nodes - 1 edges (this is enough).
	WHILE @@FETCH_STATUS = 0 AND @EdgeCount < @NodeCount - 1
	BEGIN
		-- Get the clusters for this edge
		SELECT @FromCluster = ClusterNum FROM #MSTNodes WHERE Id = @FromNode
		SELECT @ToCluster = ClusterNum FROM #MSTNodes WHERE Id = @ToNode

		-- If the edge ends in different clusters, the edge is safe, so add it to the MST.
		IF (@FromCluster <> @ToCluster)
		BEGIN
			-- Merge the two clusters by updating the cluster number of the "to cluster" to the
			-- cluster number of the "from cluster".
			UPDATE #MSTNodes
			SET ClusterNum = @FromCluster
			WHERE ClusterNum = @ToCluster

			-- Insert the edge into the result and increment the edge count
			INSERT #MST VALUES (@FromNode, @ToNode)
			SET @EdgeCount = @EdgeCount + 1
		END

		-- Get the next edge
		FETCH NEXT FROM EdgeCursor INTO @FromNode, @ToNode	
	END

	-- Close and deallocate the cursor
	CLOSE EdgeCursor
	DEALLOCATE EdgeCursor

	-- Verify that we have enough edges to connect the whole graph.
	IF (SELECT COUNT(*) FROM #MST) < @NodeCount - 1
	BEGIN
		DROP TABLE #MSTNodes
		DROP TABLE #MST
		RAISERROR('Error: The graph is not connected.', 1, 1)
		ROLLBACK TRAN
		RETURN 1
	END
		
	-- Select the results.
    SELECT mst.FromNode, mst.ToNode,
		node1.Name AS FromName, node2.Name AS ToName
	FROM #MST mst
	JOIN dbo.Node node1 ON mst.FromNode = node1.Id
	JOIN dbo.Node node2 ON mst.ToNode = node2.id
	ORDER BY mst.FromNode, mst.ToNode
	
	DROP TABLE #MSTNodes
	DROP TABLE #MST	
	COMMIT TRAN
	RETURN 0
END