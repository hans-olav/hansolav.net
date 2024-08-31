-- Insert test data for the USA map
DELETE FROM dbo.Edge
DELETE FROM dbo.Node

INSERT dbo.Node (Id, Name) VALUES (1, 'Seattle')
INSERT dbo.Node (Id, Name) VALUES (2, 'San Francisco')
INSERT dbo.Node (Id, Name) VALUES (3, 'Las Vegas')
INSERT dbo.Node (Id, Name) VALUES (4, 'Los Angeles')
INSERT dbo.Node (Id, Name) VALUES (5, 'Denver')
INSERT dbo.Node (Id, Name) VALUES (6, 'Minneapolis')
INSERT dbo.Node (Id, Name) VALUES (7, 'Dallas')
INSERT dbo.Node (Id, Name) VALUES (8, 'Chicago')
INSERT dbo.Node (Id, Name) VALUES (9, 'Washington DC')
INSERT dbo.Node (Id, Name) VALUES (10, 'Boston')
INSERT dbo.Node (Id, Name) VALUES (11, 'New York')
INSERT dbo.Node (Id, Name) VALUES (12, 'Miami')

INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (1, 2, 1306.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (1, 5, 2161.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (1, 6, 2661.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (2, 1, 1306.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (2, 3, 919.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (2, 4, 629.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 2, 919.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 4, 435.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 5, 1225.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 7, 1983.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (4, 2, 629.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (4, 3, 435.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 1, 2161.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 3, 1225.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 6, 1483.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 7, 1258.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 1, 2661.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 5, 1483.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 7, 1532.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 8, 661.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 3, 1983.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 5, 1258.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 6, 1532.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 9, 2113.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 12, 2161.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (8, 6, 661.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (8, 9, 1145.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (8, 10, 1613.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 7, 2113.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 8, 1145.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 10, 725.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 11, 383.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 12, 1709.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (10, 8, 1613.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (10, 9, 725.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (10, 11, 338.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (11, 9, 383.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (11, 10, 338.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (11, 12, 2145.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (12, 7, 2161.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (12, 9, 1709.000)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (12, 11, 2145.000)

-- Test breadth-first
EXEC usp_Breadth_First 1

-- Test Dijkstra's
EXEC usp_Dijkstra 1

-- Test Prim's
EXEC usp_Prim

-- Test Kruskal's
EXEC usp_Kruskal

-----------------------------------------------------------------------
-- Test topological sort

DELETE FROM dbo.Edge
DELETE FROM dbo.Node

INSERT dbo.Node (Id, Name) VALUES (1, 'Watch')
INSERT dbo.Node (Id, Name) VALUES (2, 'Jacket')
INSERT dbo.Node (Id, Name) VALUES (3, 'Shirt')
INSERT dbo.Node (Id, Name) VALUES (4, 'Tie')
INSERT dbo.Node (Id, Name) VALUES (5, 'Pants')
INSERT dbo.Node (Id, Name) VALUES (6, 'Undershorts')
INSERT dbo.Node (Id, Name) VALUES (7, 'Belt')
INSERT dbo.Node (Id, Name) VALUES (8, 'Shoes')
INSERT dbo.Node (Id, Name) VALUES (9, 'Socks')

INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 4, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (3, 7, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (4, 2, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 7, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (5, 8, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 5, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (6, 8, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (7, 2, NULL)
INSERT dbo.Edge (FromNode, ToNode, [Weight]) VALUES (9, 8, NULL)

EXEC usp_TopologicalSort