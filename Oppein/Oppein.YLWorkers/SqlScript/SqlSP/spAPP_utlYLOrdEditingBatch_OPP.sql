
/*
	注意：自定义类型mOrdTableType_OPP actions 的值为2、3、4（1为替换、2为添加、3为删除、4为修改）
*/

CREATE PROC [dbo].[spAPP_utlYLOrdEditingBatch_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)
	,@ordSource NVARCHAR(50)=NULL
    ,@YLOrdItmTable YLOrdTableType_OPP READONLY
	,@YLOrdTotalTable YLOrdTotalTableType_OPP READONLY
AS 
SET NOCOUNT ON;

IF EXISTS(SELECT TOP 1 1 FROM @YLOrdItmTable)
BEGIN
	--判断操作页签类型
	IF @pageName IN(N'普通五金')
	BEGIN
		--执行处理五金存储
		--SELECT 1
		EXEC [dbo].[spAPP_utlYLOrdEditingBatch_WJ_OPP] @ordID=@ordID,@pageName=@pageName,@ordSource=@ordSource,@YLOrdItmTable=@YLOrdItmTable,@YLOrdTotalTable=@YLOrdTotalTable
	END
	ELSE
	BEGIN
		/*
			该存储执行操作顺序 删除操作、新增操作、修改操作（不修改BOM数量）、保存原始记录、保存日志
		*/
		IF EXISTS(SELECT 1 FROM @YLOrdItmTable WHERE actions=2 AND itmfCode IS NULL)
		BEGIN
			RAISERROR(N'存在新增的物料品项系为空，请确认该页签是否可新增物料。',16,1)
		END
		ELSE
		BEGIN
			--公用参数
			DECLARE @WhileRow SMALLINT,@While SMALLINT,@itmIDNew INT,@itmIDSA INT,@itmID INT,@itmIDInstance SMALLINT,@olnID INT,@olnIDInstance SMALLINT,@oriReqQty DECIMAL(18,2),@primaryUOMCode NCHAR(5),@AsOfDate datetime =GETDATE()
					,@errMsg NVARCHAR(255)
			--删除操作表
			DECLARE @BOMData TABLE(RowID SMALLINT,itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,itmIDParent INT,itmIDParentInstance SMALLINT,itmIDSA INT,actions TINYINT,oriReqQty DECIMAL(18,2),primaryUOMCode NCHAR(5))
			--新增操作表
			DECLARE @addBOMData TABLE(RowID SMALLINT IDENTITY(1,1),itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,itmItemNumber NVARCHAR(50),itmDescription NVARCHAR(100),itmIDSA INT,oriReqQty DECIMAL(18,2),primaryUOMCode NCHAR(5)
									,dlCode NCHAR(2),dimCX DECIMAL(18,2),dimCY DECIMAL(18,2),dimCZ DECIMAL(18,2),dimFX DECIMAL(18,2),dimFY DECIMAL(18,2),dimFZ DECIMAL(18,2),itmfCode NVARCHAR(50),corCode NVARCHAR(50),topSurCode NVARCHAR(50),edgeCode NVARCHAR(6)
									,Factory NVARCHAR(50),Duty NVARCHAR(50),PlateCategory NVARCHAR(50),LegacyPrice DECIMAL(18,2),info1 NVARCHAR(50),info2 NVARCHAR(50)
									,info3 NVARCHAR(50),info5 NVARCHAR(50),info6 NVARCHAR(255),info14 NVARCHAR(50),info15 NVARCHAR(50))
			--自定义属性表
			DECLARE @itmAvTable TABLE(itmID INT,atbID INT,itmValue NVARCHAR(255))
			--保存芯材与花色（材料）
			DECLARE @mrTable TABLE(RowID INT,itmRowID INT,itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,topSurCode NVARCHAR(50),corCode NVARCHAR(50),botSurCode NVARCHAR(50))
			--修改封边
			DECLARE @trmID TINYINT=2,@msqID TINYINT=1,@opsID TINYINT=1
			DECLARE @edgeData TABLE(itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,itmeEdgeNo TINYINT,surCode NVARCHAR(50),edgeThick DECIMAL(18,2),itmeLength DECIMAL(18,2),itmeWidth DECIMAL(18,2))
			DECLARE @optEdgeData TABLE(RowID INT,itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,topSurCode NVARCHAR(50),itmeWidth DECIMAL(18,2),edgeThick DECIMAL(18,2),surCode NVARCHAR(50),dimFX DECIMAL(18,2),dimFY DECIMAL(18,2))
			--修改尺寸
			DECLARE @itmDimTable Table(itmID INT,dimID TINYINT,dimX decimal(18,2),dimY decimal(18,2),dimZ decimal(18,2))
			--一、删除操作（数据处理）
			--1.1将要删除的数据添加到临时表中
			INSERT INTO @BOMData(RowID,itmID,itmIDInstance,olnID,olnIDInstance,itmIDSA,actions,oriReqQty,primaryUOMCode)
			SELECT 
				ROW_NUMBER()OVER(ORDER BY YLOrd.olnID,YLOrd.itmID) RowID
				,YLOrd.itmID
				,YLOrd.itmIDInstance
				,YLOrd.olnID
				,YLOrd.olnIDInstance
				,cs.itmIDSA
				,YLOrd.actions
				,cs.oriReqQty AS oriReqQty
				,cs.primaryUOMCode
			FROM @YLOrdItmTable YLOrd
			JOIN CUS_YLOrdOriginalBOMData_OPP cs(NOLOCK) ON cs.itmID=YLOrd.itmID
				AND cs.itmIDInstance=YLOrd.itmIDInstance
				AND cs.olnID=YLOrd.olnID
				AND cs.olnIDInstance=YLOrd.olnIDInstance
			WHERE YLOrd.actions=3
			--1.2获取删除MP或MA层级的下级品项
			INSERT INTO @BOMData(RowID,itmID,itmIDParent,itmIDParentInstance,olnID,olnIDInstance,itmIDSA,actions,oriReqQty,primaryUOMCode)
			SELECT
				ROW_NUMBER()OVER(ORDER BY ori.itmID)AS RowID
				,ori.itmID AS itmIDNew
				,cs.itmIDParent
				,cs.itmIDParentInstance
				,YLOrd.olnID
				,YLOrd.olnIDInstance
				,cs.itmIDSA
				,2 AS actions
				,SUM(ori.oriReqQty) AS oriReqQty
				,itm.PrimaryUOMCode
			FROM @YLOrdItmTable YLOrd
			JOIN CUS_YLOrdOriginalBOMData_OPP cs(NOLOCK) ON cs.itmID=YLOrd.itmID
				AND cs.itmIDInstance=YLOrd.itmIDInstance
				AND cs.olnID=YLOrd.olnID
				AND cs.olnIDInstance=YLOrd.olnIDInstance
			JOIN dbo.OrderItems ori ON ori.itmIDParent = YLOrd.itmID
				AND ori.itmIDParentInstance=YLOrd.itmIDInstance
				AND ori.olnID=YLOrd.olnID
				AND ori.olnIDInstance=YLOrd.olnIDInstance
			JOIN dbo.Items itm ON itm.itmID = ori.itmID
			WHERE YLOrd.actions=3
			GROUP BY ori.itmID
				,cs.itmIDParent
				,cs.itmIDParentInstance
				,YLOrd.olnID
				,YLOrd.olnIDInstance
				,itm.PrimaryUOMCode
				,cs.itmIDSA

			--二、新增操作（数据处理）
			--2.1 复制新增
			INSERT INTO @addBOMData(itmID,itmIDInstance,olnID,olnIDInstance,itmItemNumber,itmDescription,itmIDSA,oriReqQty,primaryUOMCode,dlCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ
				,itmfCode,corCode,topSurCode,edgeCode,Factory,Duty,PlateCategory,LegacyPrice,info1,info2,info3,info5,info6,info14,info15)
			SELECT 
				  Org.itmIDParent
				 ,Org.itmIDParentInstance
				 ,Org.olnID
				 ,Org.olnIDInstance
				 ,REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(25),GETDATE(),121),N'-',N''),N':',N''),N' ',N'')+N'1'+CAST(ROW_NUMBER()OVER(ORDER BY YLOrd.olnID)AS NVARCHAR(3)) AS itmItemNumber
				 ,YLOrd.itmDescription
				 ,Org.itmIDSA
				 ,ISNULL(YLOrd.oriReqQty,1) AS oriReqQty
				 ,Org.primaryUOMCode
				 ,(CASE WHEN @pageName IN(N'木框门')THEN N'MA' END)AS dlCode
				 ,YLOrd.dimCX
				 ,YLOrd.dimCY
				 ,YLOrd.dimCZ
				 ,YLOrd.dimFX
				 ,YLOrd.dimFY
				 ,YLOrd.dimFZ
				 ,(CASE WHEN YLOrd.itmfCode IS NOT NULL THEN YLOrd.itmfCode 
					WHEN @pageName IN(N'木框门') THEN N'BFMKM'
				   END) AS itmfCode
				 ,YLOrd.corCode
				 ,YLOrd.topSurCode
				 ,YLOrd.edgeCode
				 ,YLOrd.Factory
				 ,YLOrd.Duty
				 ,YLOrd.PlateCategory
				 ,YLOrd.LegacyPrice
				 ,YLOrd.info1
				 ,YLOrd.info2
				 ,YLOrd.info3
				 ,YLOrd.info5
				 ,YLOrd.info6
				 ,YLOrd.info14
				 ,YLOrd.info15
			FROM @YLOrdItmTable YLOrd
			LEFT JOIN(
				SELECT 
					ROW_NUMBER()OVER(PARTITION BY cs.itmID,cs.olnID ORDER BY cs.olnIDInstance,cs.itmIDInstance)AS RowID
					,cs.itmID
					,cs.itmIDInstance
					,cs.olnID
					,cs.olnIDInstance
					,cs.itmIDParent
					,cs.itmIDParentInstance
					,cs.itmIDSA
					,cs.oriReqQty
					,cs.primaryUOMCode
				FROM CUS_YLOrdOriginalBOMData_OPP cs(NOLOCK)
				WHERE cs.ordId=@ordID
					AND cs.pageName=@pageName
			)Org ON Org.itmID=YLOrd.itmID AND Org.olnID=YLOrd.olnID 
			WHERE YLOrd.actions=2
				--AND YLOrd.itmfCode IS NOT NULL
				AND YLOrd.itmID IS NOT NULL
				AND YLOrd.olnID IS NOT NULL

			--2.2 直接新增
			IF EXISTS(SELECT 1 FROM @YLOrdItmTable YLOrd WHERE YLOrd.actions=2 AND NOT(YLOrd.itmID IS NOT NULL AND YLOrd.olnID IS NOT NULL))
			BEGIN
				SELECT TOP 1
					@itmID=ori.itmID
					,@itmIDInstance=ori.itmIDInstance
					,@olnID=ori.olnID
					,@olnIDInstance=ori.olnIDInstance
				FROM dbo.OrderItems ori
				JOIN dbo.OrderLines oln ON oln.olnID = ori.olnID
				WHERE oln.ordID=@ordID 
					AND ori.dlCode=N'SA'
				ORDER BY oln.olnID

				INSERT INTO @addBOMData(itmID,itmIDInstance,olnID,olnIDInstance,itmItemNumber,itmDescription,itmIDSA,oriReqQty,primaryUOMCode,dlCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ
					,itmfCode,corCode,topSurCode,edgeCode,Factory,Duty,PlateCategory,LegacyPrice,info1,info2,info3,info5,info6,info14,info15)
				SELECT 
					 @itmID AS itmIDParent
					 ,@itmIDInstance AS itmIDParentInstance
					 ,@olnID AS olnID
					 ,@olnIDInstance AS olnIDInstance
					 ,REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(25),GETDATE(),121),N'-',N''),N':',N''),N' ',N'')+N'2'+CAST(ROW_NUMBER()OVER(ORDER BY YLOrd.olnID)AS NVARCHAR(3)) AS itmItemNumber
					 ,YLOrd.itmDescription
					 ,@itmID AS itmIDSA
					 ,ISNULL(YLOrd.oriReqQty,1) AS oriReqQty
					 ,N'EA' AS primaryUOMCode
					 ,(CASE WHEN @pageName IN(N'木框门')THEN N'MA' END)AS dlCode
					 ,YLOrd.dimCX
					 ,YLOrd.dimCY
					 ,YLOrd.dimCZ
					 ,YLOrd.dimFX
					 ,YLOrd.dimFY
					 ,YLOrd.dimFZ
					 ,(CASE WHEN YLOrd.itmfCode IS NOT NULL THEN YLOrd.itmfCode 
							WHEN @pageName IN(N'木框门') THEN N'BFMKM'
						END) AS itmfCode
					 ,YLOrd.corCode
					 ,YLOrd.topSurCode
					 ,YLOrd.edgeCode
					 ,YLOrd.Factory
					 ,YLOrd.Duty
					 ,YLOrd.PlateCategory
					 ,YLOrd.LegacyPrice
					 ,YLOrd.info1
					 ,YLOrd.info2
					 ,YLOrd.info3
					 ,YLOrd.info5
					 ,YLOrd.info6
					 ,YLOrd.info14
					 ,YLOrd.info15
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=2
					--AND YLOrd.itmfCode IS NOT NULL
					AND NOT(YLOrd.itmID IS NOT NULL AND YLOrd.olnID IS NOT NULL)
			END

			--三、修改操作(数据处理)
			--3.1 数据处理操作
			--3.1.1 处理尺寸（只涉及到尺寸的修改与增加，不涉及删除尺寸）
			--处理烤漆该页签尺寸，完工尺寸与截切尺寸一致 2018.08.03
			IF @pageName IN(N'烤漆柜身',N'烤漆背板',N'烤漆功能件',N'烤漆门抽面',N'大理石台面')
			BEGIN
				;WITH dimT AS
				(
					SELECT 
						 ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID ORDER BY YLOrd.olnID)AS RowID
						,YLOrd.itmID
						,ISNULL(YLOrd.dimFX,0) AS dimX
						,ISNULL(YLOrd.dimFY,0) AS dimY
						,ISNULL(YLOrd.dimFZ,0) AS dimZ
					FROM @YLOrdItmTable YLOrd
					WHERE YLOrd.actions=4
						AND NOT(YLOrd.dimFX IS NULL AND YLOrd.dimFY IS NULL AND YLOrd.dimFZ IS NULL) 
				),dimTT AS
				(
					SELECT t.itmID
						,1 AS dimID
						,t.dimX
						,t.dimY
						,t.dimZ
					FROM dimT t 
					WHERE t.RowID=1
					UNION ALL
					SELECT t.itmID
						,3 AS dimID
						,t.dimX
						,t.dimY
						,t.dimZ
					FROM dimT t 
					WHERE t.RowID=1
				)
				INSERT INTO @itmDimTable(itmID,dimID,dimX,dimY,dimZ)
				SELECT 
					t.itmID
					,t.dimID
					,t.dimX
					,t.dimY
					,t.dimZ 
				FROM dimTT t 
				WHERE NOT EXISTS(SELECT 1 FROM dbo.ItemDimensions dim WHERE dim.itmID = t.itmID AND dim.dimID=t.dimID AND dim.dimX=t.dimX AND dim.dimY=t.dimY AND dim.dimZ=t.dimZ)
			END
			ELSE
			BEGIN
				;WITH dimAll AS
				(
					SELECT 
						 ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID ORDER BY YLOrd.olnID)AS RowID
						,YLOrd.itmID
						,1 AS dimID
						,ISNULL(YLOrd.dimFX,0) AS dimX
						,ISNULL(YLOrd.dimFY,0) AS dimY
						,ISNULL(YLOrd.dimFZ,0) AS dimZ
					FROM @YLOrdItmTable YLOrd
					WHERE YLOrd.actions=4
						AND NOT(YLOrd.dimFX IS NULL AND YLOrd.dimFY IS NULL AND YLOrd.dimFZ IS NULL)
					UNION ALL
					SELECT 
						 ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID ORDER BY YLOrd.olnID)AS RowID
						,YLOrd.itmID
						,3 AS dimID
						,(CASE WHEN @ordSource=N'CAD' AND cs.info3 like N'%翻%' THEN ISNULL(YLOrd.dimCY,0) ELSE ISNULL(YLOrd.dimCX,0) END)dimX
						,(CASE WHEN @ordSource=N'CAD' AND cs.info3 like N'%翻%' THEN ISNULL(YLOrd.dimCX,0) ELSE ISNULL(YLOrd.dimCY,0) END)dimY
						--,ISNULL(YLOrd.dimCX,0) AS dimX
						--,ISNULL(YLOrd.dimCY,0) AS dimY
						,ISNULL(YLOrd.dimCZ,0) AS dimZ
					FROM @YLOrdItmTable YLOrd
					LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] cs ON cs.itmID=YLOrd.itmID
						AND cs.itmIDInstance=YLOrd.itmIDInstance
						AND cs.olnID=YLOrd.olnID
						AND cs.olnIDInstance=YLOrd.olnIDInstance
						AND cs.pageName=N'吸塑门'
					WHERE YLOrd.actions=4
						AND NOT(YLOrd.dimCX IS NULL AND YLOrd.dimCY IS NULL AND YLOrd.dimCZ IS NULL)
				)
				INSERT INTO @itmDimTable(itmID,dimID,dimX,dimY,dimZ)
				SELECT 
					t.itmID
					,t.dimID
					,t.dimX
					,t.dimY
					,t.dimZ 
				FROM dimAll t 
				WHERE NOT EXISTS(SELECT 1 FROM dbo.ItemDimensions dim WHERE dim.itmID = t.itmID AND dim.dimID=t.dimID AND dim.dimX=t.dimX AND dim.dimY=t.dimY AND dim.dimZ=t.dimZ)
			END
			--3.1.2 处理封边数据(导入封边面材等信息)
			INSERT INTO @optEdgeData
			SELECT 
				ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID,YLOrd.topSurCode ORDER BY itme.itmeThickness) AS RowID	--1为薄边，2为厚边
				,YLOrd.itmID
				,YLOrd.itmIDInstance
				,YLOrd.olnID
				,YLOrd.olnIDInstance
				,YLOrd.topSurCode
				,YLOrd.dimFZ
				,itme.itmeThickness
				,itme.surCode
				,YLOrd.dimFX
				,YLOrd.dimFY
			FROM @YLOrdItmTable YLOrd
			LEFT JOIN dbo.ItemEdgesSurCode_OPP itme(NOLOCK) ON itme.TopSurCode=YLOrd.topSurCode 
				AND CONVERT(DECIMAL(18,0),itme.itmeWidth)=CONVERT(DECIMAL(18,0), YLOrd.dimFZ)
			JOIN ItemDimensions dimF (NOLOCK) ON dimF.itmID = YLOrd.itmID AND dimF.dimID=1
			OUTER APPLY
			(  
				SELECT 
					MAX(Case when orie.orieEdgeNo=4 then IsNull(iatbv.itmavValue,0) end) as Edge1  
					,MAX(Case when orie.orieEdgeNo=2 then IsNull(iatbv.itmavValue,0) end) as Edge2  
					,MAX(Case when orie.orieEdgeNo=3 then IsNull(iatbv.itmavValue,0) end) as Edge3  
					,MAX(Case when orie.orieEdgeNo=1 then IsNull(iatbv.itmavValue,0) end) as Edge4  
				FROM dbo.OrderItemEdges orie (NOLOCK)  
					JOIN dbo.SurfaceSourceItems ssi (NOLOCK) ON orie.surCode=ssi.surCode  
					JOIN dbo.ItemAttributeValues iatbv (NOLOCK) ON ssi.itmID=iatbv.itmID  
					JOIN dbo.Attributes atb (NOLOCK) ON iatbv.atbID=atb.atbID  
					JOIN dbo.AttributeCategories atbc (NOLOCK) ON atb.atbcID=atbc.atbcID  
				WHERE  YLOrd.itmID=orie.itmID 
					AND YLOrd.itmIDInstance=orie.itmIDInstance
					AND YLOrd.olnID=orie.olnID 
					AND YLOrd.olnIDInstance=orie.olnIDInstance  
					AND orie.surCode<>N'No Edge Application'  
					AND atb.atbCode=N'Edge_Thickness_Code' 
					AND atbc.atbcCode=N'Item Info'
			) iatb
			LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge ON cEdge.edge1=iatb.Edge1
				AND cEdge.edge2=iatb.Edge2
				AND cEdge.edge3=iatb.Edge3
				AND cEdge.edge4=iatb.Edge4
			JOIN dbo.OrderItemMaterials oriMat(NOLOCK) ON oriMat.itmID = YLOrd.itmID
					AND oriMat.itmIDInstance = YLOrd.itmIDInstance
					AND oriMat.olnID = YLOrd.olnID
					AND oriMat.olnIDInstance = YLOrd.olnIDInstance
			WHERE YLOrd.actions=4 
				AND YLOrd.edgeCode IS NOT NULL
				AND YLOrd.edgeCode !=N'0000'
				AND NOT(YLOrd.dimFZ=dimF.dimZ AND YLOrd.edgeCode=ISNULL(cEdge.edgeCode,N'') AND YLOrd.topSurCode=oriMat.TopSurCode)
			--判断封边的面材是否存在
			SELECT TOP 1 @errMsg=N'花色:'+topSurCode+N' 封边宽：'+CAST(itmeWidth AS NVARCHAR(10))+N',' FROM @optEdgeData WHERE surCode IS NULL
			IF @errMsg IS NOT NULL
			BEGIN
				SET @errMsg+=N'不存在面材代码'
				RAISERROR(@errMsg,16,1);
			END
			ELSE
			BEGIN
				--将封边数据保存到@edgeData表中
				;WITH edgeData AS
				(
					SELECT 
						YLOrd.itmID
						,cus.edge1 AS [4]
						,cus.edge2 AS [2]
						,cus.edge3 AS [3]
						,cus.edge4 AS [1]
						,YLOrd.topSurCode
						,YLOrd.dimFZ AS itmeWidth
					FROM @YLOrdItmTable YLOrd
					JOIN dbo.CUS_mOrdItemEdgeCode_OPP cus(NOLOCK) ON cus.edgeCode = YLOrd.edgeCode
					WHERE YLOrd.actions=4
						AND YLOrd.edgeCode IS NOT NULL
						AND YLOrd.edgeCode !=N'0000'
				),cEdgeData AS
				(
					SELECT 
						itmID
						,itmeEdgeNo
						,topSurCode
						,edgeThick
						,itmeWidth
					FROM edgeData
					UNPIVOT(edgeThick FOR itmeEdgeNo IN([1],[2],[3],[4]))AS up
				)
				INSERT INTO @edgeData
				SELECT 
					edge.itmID
					,optEdge.itmIDInstance
					,optEdge.olnID
					,optEdge.olnIDInstance
					,edge.itmeEdgeNo
					,optEdge.surCode
					,optEdge.edgeThick
					,(CASE WHEN edge.itmeEdgeNo IN(1,3) THEN optEdge.dimFX ELSE optEdge.dimFX END)AS itmeLength
					,optEdge.itmeWidth
				FROM cEdgeData edge
				JOIN @optEdgeData optEdge ON optEdge.itmID = edge.itmID
					AND optEdge.topSurCode = edge.topSurCode
					AND optEdge.itmeWidth = edge.itmeWidth
					AND optEdge.RowID=edge.edgeThick
					AND optEdge.edgeThick !=0 
			END
			--3.1.3 添加自定义属性
			DELETE FROM @itmAvTable
			INSERT INTO @itmAvTable(itmID, atbID, itmValue)
			SELECT 
				tb.itmID,tb.atbID,tb.itmavValue 
			FROM 
			(SELECT 
					YLOrd.itmID
					,MAX(CASE WHEN YLOrd.info1 IS NOT NULL OR YLOrd.info2 IS NOT NULL THEN REPLACE(YLOrd.info1,N'/',N'')+N'/'+ISNULL(YLOrd.info2,N'') END) AS itmavValue
					,115 AS atbID
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=4
					AND @pageName=N'吸塑门'
					AND @ordSource=N'CAD'
					AND (YLOrd.info1 IS NOT NULL OR YLOrd.info2 IS NOT NULL)
				GROUP BY YLOrd.itmID
				UNION ALL
				SELECT 
					YLOrd.itmID
					,MAX(YLOrd.info1) AS itmavValue
					,115 AS atbID
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=4
					AND @pageName=N'普通顶线'
					AND YLOrd.info1 IS NOT NULL
				GROUP BY YLOrd.itmID
				UNION ALL
				SELECT 
					YLOrd.itmID
					,MAX(YLOrd.info2) AS itmavValue
					,44 AS atbID
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=4
					AND @pageName=N'普通顶线'
					AND YLOrd.info2 IS NOT NULL
				GROUP BY YLOrd.itmID
				UNION ALL
				SELECT 
					YLOrd.itmID
					,MAX(YLOrd.info3) AS itmavValue
					,45 AS atbID
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=4
					AND @pageName NOT IN(N'普通顶线',N'木框门芯')
					AND YLOrd.info3 IS NOT NULL
					AND LEN(LTRIM(YLOrd.info3))>0
				GROUP BY YLOrd.itmID
			)tb 
			WHERE NOT EXISTS(SELECT 1 FROM dbo.ItemAttributeValues t(NOLOCK) WHERE t.itmID=tb.itmID AND t.atbID=tb.atbID AND tb.itmavValue=ISNULL(t.itmavValue,N''))

			--3.1.4 取Info3的值
			--取Info3的值(info3在“普通顶线”，'木框门芯'页签中表示材料)
			DELETE FROM @mrTable
			IF @pageName IN(N'普通顶线',N'木框门芯')
			BEGIN
				INSERT INTO @mrTable( RowID,itmRowID,itmID ,itmIDInstance ,olnID ,olnIDInstance ,topSurCode ,corCode ,botSurCode )
				SELECT 
					row_number()over(partition by YLOrd.itmID,YLOrd.itmIDInstance,YLOrd.olnID,YLOrd.olnIDInstance order by getdate())AS rowID
					,ROW_NUMBER()over(partition by YLOrd.itmID order by getdate())AS itmRowID
					,YLOrd.itmID
					,YLOrd.itmIDInstance
					,YLOrd.olnID
					,YLOrd.olnIDInstance
					,itmm.TopSurCode
					,itmm.corCode
					,itmm.BotSurCode
				FROM @YLOrdItmTable YLOrd
				JOIN dbo.Items itm(NOLOCK) ON itm.itmDescription2=YLOrd.info3
				JOIN dbo.MaterialSourceItems itmm(NOLOCK) ON itmm.itmID = itm.itmID
				WHERE YLOrd.actions=4 
					AND @pageName IN(N'普通顶线',N'木框门芯')
					AND YLOrd.info3 IS NOT NULL
					AND YLOrd.itmID != itm.itmID
				IF NOT EXISTS(SELECT TOP 1 1 FROM @mrTable) 
				BEGIN
					--取Materials表matDescription
					INSERT INTO @mrTable( RowID,itmRowID,itmID ,itmIDInstance ,olnID ,olnIDInstance ,topSurCode ,corCode ,botSurCode )
					SELECT 
						row_number()over(partition by YLOrd.itmID,YLOrd.itmIDInstance,YLOrd.olnID,YLOrd.olnIDInstance order by getdate())AS rowID
						,row_number()over(partition by YLOrd.itmID order by getdate())AS itmRowID
						,YLOrd.itmID
						,YLOrd.itmIDInstance
						,YLOrd.olnID
						,YLOrd.olnIDInstance
						,mr.TopSurCode
						,mr.corCode
						,mr.BotSurCode
					FROM @YLOrdItmTable YLOrd
					JOIN dbo.Materials mr(NOLOCK) ON mr.matDescription = YLOrd.info3
					WHERE YLOrd.actions=4 
						AND YLOrd.info3 IS NOT NULL
						AND LEN(LTRIM(YLOrd.info3))>0
				END
			END

			--开启事务
			BEGIN TRANSACTION
			--一、删除操作（数据执行）

			--------------add hyz 20180913 （暂时注释）
			--INSERT INTO dbo.handModifyLog_RJZ_OPP( ordID, olnID, itmID, itmgNCNO,type )
			--SELECT
			--	DISTINCT
			--	@ordID
			--	,d.olnID
			--	,d.itmID
			--	,icm.itmgCNCOrigFileName
			--	,N'modify'
			--FROM dbo.ItemCNCGeometry icm(NOLOCK)
			--JOIN @BOMData d ON d.itmID = icm.itmID
			--WHERE d.actions=3
			-------------------------

			SELECT @WhileRow=MAX(RowID) FROM @BOMData
			SET @While=1;
			WHILE @While < @WhileRow + 1
			BEGIN
				--删除BOM
				SELECT 
					@olnID=del.olnID
					,@olnIDInstance=del.olnIDInstance
					,@itmID=del.itmID
					,@itmIDInstance=del.itmIDInstance
					,@itmIDNew=del.itmID
					,@oriReqQty=del.oriReqQty
					,@primaryUOMCode=del.primaryUOMCode
					,@itmIDSA=del.itmIDSA
				FROM @BOMData del
				WHERE del.RowID=@While
					AND del.actions=3
				IF @@ROWCOUNT = 1
				BEGIN
					--删除BOM
					EXEC dbo.spAPP_utlProcessOrderItemEditing 
						@olnID=@olnID
						,@olnIDInstance=@olnIDInstance
						,@itmID=@itmID
						,@itmIDInstance=@itmIDInstance
						,@Action=3
						,@itmIDNew=@itmIDNew
						,@oriReqQtyNew=@oriReqQty
						,@PrimaryUOMCode=@primaryUOMCode
						,@TransUOMCodeNew=@primaryUOMCode
						,@rotID=NULL
						,@rotIDNew=NULL
						,@itmIDpdv=NULL
						,@itmIDTop=@itmIDSA	--Use the SA level ori instance
						,@AsOfDate=@AsOfDate
						-- configuration settings
						,@EnableAllocationReassignments = 0
						,@EnableCustomProperties  = 1
						,@EnableSurfaceAlternates  = 1
						,@EnableParametricDimensions  = 1
						,@EnablePurchasedDemandReassignments  = 0
						,@EnableConditionalComponents  = 1
						,@EnableImpliedComponents  = 1
						,@EnableCriteriaMatchReplacementParts  = 1
						,@EnableExactComponentMatchReplacementParts  = 1
						,@EnableConfiguredItemReplacementParts  = 1
						,@EnableRoutingReassignments = 2
						,@EnableMultiLevelRoutingReassignments  = 0
						,@EnableConditionalOperations  = 1
						,@EnableProcessedCostComputation  = 0
						,@EnableOutsourcedOperations  = 0
						,@EnableRollupBOMMatching  = 0 -- Enable Rollup BOM Match Processing. [0] = False, [1] = Match, [2] = Match and Purge
						,@EnableOrderItemBackscheduleComputation  = 1
						,@EnableProcessGroupFillFactor  = 0
						-- additional parameter-matched setting values used in processing
						,@MaxBOMProcessingIterations  = 20 -- Maximum [number] of iterations when performing iterative BOM processing.
						,@WorkOrderStartDateCalculationMethod  = 0 -- Determines the technique used to calculate Work Order Start Date: [0] - Process Group Offset, [1] - Operation Schedule Offset
						,@InitialOrderItemStatusValue  = 11000 -- Initial [Status Value] for Order Items
						,@EnableBOMDebugInfoLogging  = 0 -- Enables debug info logging in Application Log during BOM Processing. [0] = False, [1] = True
						,@MaxItemEdgesInCriteriaProperties  = 4 -- Maximum [number] of item edges to process in Criteria Property processing.
						,@InitialOrderLineInstanceStatusValue  = 1000
						,@FirmedOrderLineInstanceStatusValue = 1200
						,@DefaultSARoutingCode  = 15100
						,@WorkOrderStartDateOperationScheduleOffsetMode  = 1 -- Determines the technique used to calculate Operation Schedule Offset Work Order Start Date: [0] - Time Optimized,[1] - Yield Optimized
						,@CLRDebugMode  = default -- Sets flag to produce extended textual processing logging. See CLR SP call below for more.
						,@OutputCLRDebugging  = default -- When CLR Debug Mode is set and this code is run from SQL Server Management Studio, it prints and outputs log.
			
				END
				--添加BOM
				SELECT
					@itmIDNew=addBom.itmID
					,@olnID=addBom.olnID
					,@olnIDInstance=addBom.olnIDInstance
					,@itmID=addBom.itmIDParent					--注意添加BOM的上级品项为删除品项的上级品项
					,@itmIDInstance=addBom.itmIDParentInstance	--注意添加BOM的上级品项实例为删除品项的上级品项实例
					,@oriReqQty=addBom.oriReqQty
					,@primaryUOMCode=addBom.primaryUOMCode
					,@itmIDSA=addBom.itmIDSA
				FROM @BOMData addBom
				WHERE addBom.RowID=@While
					AND addBom.actions=2
				IF @@ROWCOUNT = 1
				BEGIN
					--添加BOM
					EXEC dbo.spAPP_utlProcessOrderItemEditing
						@olnID=@olnID
						,@olnIDInstance=@olnIDInstance
						,@itmID=@itmID
						,@itmIDInstance=@itmIDInstance
						,@Action=2
						,@itmIDNew=@itmIDNew
						,@oriReqQtyNew=@oriReqQty
						,@PrimaryUOMCode=@primaryUOMCode
						,@TransUOMCodeNew=@primaryUOMCode
						,@rotID=NULL
						,@rotIDNew=NULL
						,@itmIDpdv=NULL
						,@itmIDTop=@itmIDSA	--Use the SA level ori instance
						,@AsOfDate=@AsOfDate
						-- configuration settings
						,@EnableAllocationReassignments = 0
						,@EnableCustomProperties  = 1
						,@EnableSurfaceAlternates  = 1
						,@EnableParametricDimensions  = 1
						,@EnablePurchasedDemandReassignments  = 0
						,@EnableConditionalComponents  = 1
						,@EnableImpliedComponents  = 1
						,@EnableCriteriaMatchReplacementParts  = 1
						,@EnableExactComponentMatchReplacementParts  = 1
						,@EnableConfiguredItemReplacementParts  = 1
						,@EnableRoutingReassignments = 2
						,@EnableMultiLevelRoutingReassignments  = 0
						,@EnableConditionalOperations  = 1
						,@EnableProcessedCostComputation  = 0
						,@EnableOutsourcedOperations  = 0
						,@EnableRollupBOMMatching  = 0 -- Enable Rollup BOM Match Processing. [0] = False, [1] = Match, [2] = Match and Purge
						,@EnableOrderItemBackscheduleComputation  = 1
						,@EnableProcessGroupFillFactor  = 0
						-- additional parameter-matched setting values used in processing
						,@MaxBOMProcessingIterations  = 20 -- Maximum [number] of iterations when performing iterative BOM processing.
						,@WorkOrderStartDateCalculationMethod  = 0 -- Determines the technique used to calculate Work Order Start Date: [0] - Process Group Offset, [1] - Operation Schedule Offset
						,@InitialOrderItemStatusValue  = 11000 -- Initial [Status Value] for Order Items
						,@EnableBOMDebugInfoLogging  = 0 -- Enables debug info logging in Application Log during BOM Processing. [0] = False, [1] = True
						,@MaxItemEdgesInCriteriaProperties  = 4 -- Maximum [number] of item edges to process in Criteria Property processing.
						,@InitialOrderLineInstanceStatusValue  = 1000
						,@FirmedOrderLineInstanceStatusValue = 1200
						,@DefaultSARoutingCode  = 15100
						,@WorkOrderStartDateOperationScheduleOffsetMode  = 1 -- Determines the technique used to calculate Operation Schedule Offset Work Order Start Date: [0] - Time Optimized,[1] - Yield Optimized
						,@CLRDebugMode  = default -- Sets flag to produce extended textual processing logging. See CLR SP call below for more.
						,@OutputCLRDebugging  = default -- When CLR Debug Mode is set and this code is run from SQL Server Management Studio, it prints and outputs log.          
			
				END
				SET @While+=1;
			END
			--操作后数据删除
			DELETE FROM @BOMData

			--二、新增操作（数据执行）
			--新增操作执行

			SELECT @WhileRow=MAX(RowID) FROM @addBOMData
			IF(@WhileRow>0)
			BEGIN
				DECLARE @newItmItemNumber nvarchar(50),@newItmDescription NVARCHAR(100),@dlCode NCHAR(2),@dimCX DECIMAL(18,2),@dimCY DECIMAL(18,2),@dimCZ DECIMAL(18,2),@dimFX DECIMAL(18,2),@dimFY DECIMAL(18,2),@dimFZ DECIMAL(18,2)
						,@Factory NVARCHAR(50),@Duty NVARCHAR(50),@PlateCategory NVARCHAR(50),@LegacyPrice DECIMAL(18,2),@itmfCode NVARCHAR(50),@corCode NVARCHAR(50),@topSurCode NVARCHAR(50),@edgeCode NVARCHAR(50)
						,@info1 NVARCHAR(50),@info2 NVARCHAR(50),@info3 NVARCHAR(50),@info5 NVARCHAR(50),@info6 NVARCHAR(50),@info14 NVARCHAR(50),@info15 NVARCHAR(50)

				-- 添加封边表
			
				DECLARE @addEdgeData TABLE(itmeEdgeNo TINYINT,edgeThick INT)
				DECLARE @addOptData TABLE(RowID INT,itmeThickness DECIMAL(19,6),surCode NVARCHAR(50))

				SET @While=1;
				WHILE @While < @WhileRow+1
				BEGIN
					--查询要添加的品项(处理烤漆该页签尺寸，完工尺寸与截切尺寸一致 2018.08.03)
					SELECT 
						@newItmItemNumber=aItm.itmItemNumber
						,@newItmDescription=aItm.itmDescription
						,@itmID=aItm.itmID
						,@itmIDInstance=aItm.itmIDInstance
						,@olnID=aItm.olnID
						,@olnIDInstance=aItm.olnIDInstance
						,@itmIDSA=aItm.itmIDSA
						,@dimCX=(CASE WHEN @pageName IN(N'烤漆柜身',N'烤漆背板',N'烤漆功能件',N'烤漆门抽面',N'大理石台面') THEN aItm.dimFX 
									WHEN @pageName IN(N'吸塑门') AND @ordSource=N'CAD' AND aItm.info3 like N'%翻%' THEN aItm.dimCY ELSE aItm.dimCX END)
						,@dimCY=(CASE WHEN @pageName IN(N'烤漆柜身',N'烤漆背板',N'烤漆功能件',N'烤漆门抽面',N'大理石台面') THEN aItm.dimFY 
									WHEN @pageName IN(N'吸塑门') AND @ordSource=N'CAD' AND aItm.info3 like N'%翻%' THEN aItm.dimCX ELSE aItm.dimCY END)
						,@dimCZ=(CASE WHEN @pageName IN(N'烤漆柜身',N'烤漆背板',N'烤漆功能件',N'烤漆门抽面',N'大理石台面') THEN aItm.dimFZ ELSE aItm.dimCZ END)
						,@dimFX=aItm.dimFX
						,@dimFY=aItm.dimFY
						,@dimFZ=aItm.dimFZ
						,@dlCode=aItm.dlCode
						,@itmfCode=aItm.itmfCode
						,@corCode=aItm.corCode
						,@topSurCode=aItm.topSurCode
						,@edgeCode=aItm.edgeCode
						,@oriReqQty=aItm.oriReqQty
						,@primaryUOMCode=aItm.primaryUOMCode
						,@info1=aItm.info1
						,@info2=aItm.info2
						,@info3=aItm.info3
						,@info5=aItm.info5
						,@info6=aItm.info6
						,@info14=aItm.info14
						,@info15=aItm.info15
						,@Factory=aItm.Factory
						,@Duty=aItm.Duty
						,@PlateCategory=aItm.PlateCategory
						,@LegacyPrice=aItm.LegacyPrice
					FROM @addBOMData aItm
					WHERE aItm.RowID=@While
					--添加品项
					INSERT INTO dbo.Items(itmItemNumber,itmDescription,itmIsPurchased,itmpID,PrimaryUOMCode,itmoID,itmEffective,itmInactive)
					SELECT @newItmItemNumber AS itmItemNumber
						,@newItmDescription AS itmDescription
						,(CASE WHEN @pageName=N'CY单' THEN 1 ELSE 0 END)AS itmIsPurchased
						,(CASE WHEN @pageName=N'CY单' THEN 3 ELSE 2 END)AS itmpID
						,@primaryUOMCode AS PrimaryUOMCode
						,1 AS itmoID
						,N'1900-01-01' AS itmEffective
						,N'9999/12/31' AS itmInactive
					SELECT @itmIDNew=SCOPE_IDENTITY()
					--添加品项系
					IF @itmfCode IS NOT NULL
					BEGIN
						INSERT INTO dbo.ItemItemFamilies(itmID,itmfCode)VALUES(@itmIDNew,@itmfCode)
					END
					IF @pageName=N'CY单'
					BEGIN
						INSERT INTO ItemPurchasing(itmID,itmDemandOffset,ippID)VALUES(@itmIDNew,0,14)
					END
					ELSE
					BEGIN
						--,@rotID INT =375,@itmLeadTime TINYINT=0,@itmMultiPartPatternL TINYINT=0,@itmMultiPartPatternW TINYINT=0,@itmMultiPartRefEdge TINYINT=0,@itmMultiPartOrient TINYINT=0,@itmCutToFit TINYINT=0
						INSERT INTO dbo.ItemManufacturing(itmID,rotID,itmLeadTime,itmMultiPartPatternL,itmMultiPartPatternW,itmMultiPartRefEdge,itmMultiPartOrient,itmCutToFit)
						VALUES(@itmIDNew,375,0,0,0,0,0,0)
					END

					--添加BOM（添加BOM与品项信息注意添加顺序）
					EXEC dbo.spAPP_utlProcessOrderItemEditing
						@olnID=@olnID
						,@olnIDInstance=@olnIDInstance
						,@itmID=@itmID
						,@itmIDInstance=@itmIDInstance
						,@Action=2
						,@itmIDNew=@itmIDNew
						,@oriReqQtyNew=@oriReqQty
						,@PrimaryUOMCode=@primaryUOMCode
						,@TransUOMCodeNew=@primaryUOMCode
						,@rotID=NULL
						,@rotIDNew=NULL
						,@itmIDpdv=NULL
						,@itmIDTop=@itmIDSA--Use the SA level ori instance
						,@AsOfDate=@AsOfDate
						-- configuration settings
						,@EnableAllocationReassignments = 0
						,@EnableCustomProperties  = 1
						,@EnableSurfaceAlternates  = 1
						,@EnableParametricDimensions  = 1
						,@EnablePurchasedDemandReassignments  = 0
						,@EnableConditionalComponents  = 1
						,@EnableImpliedComponents  = 1
						,@EnableCriteriaMatchReplacementParts  = 1
						,@EnableExactComponentMatchReplacementParts  = 1
						,@EnableConfiguredItemReplacementParts  = 1
						,@EnableRoutingReassignments = 2
						,@EnableMultiLevelRoutingReassignments  = 0
						,@EnableConditionalOperations  = 1
						,@EnableProcessedCostComputation  = 0
						,@EnableOutsourcedOperations  = 0
						,@EnableRollupBOMMatching  = 0 -- Enable Rollup BOM Match Processing. [0] = False, [1] = Match, [2] = Match and Purge
						,@EnableOrderItemBackscheduleComputation  = 1
						,@EnableProcessGroupFillFactor  = 0
						-- additional parameter-matched setting values used in processing
						,@MaxBOMProcessingIterations  = 20 -- Maximum [number] of iterations when performing iterative BOM processing.
						,@WorkOrderStartDateCalculationMethod  = 0 -- Determines the technique used to calculate Work Order Start Date: [0] - Process Group Offset, [1] - Operation Schedule Offset
						,@InitialOrderItemStatusValue  = 11000 -- Initial [Status Value] for Order Items
						,@EnableBOMDebugInfoLogging  = 0 -- Enables debug info logging in Application Log during BOM Processing. [0] = False, [1] = True
						,@MaxItemEdgesInCriteriaProperties  = 4 -- Maximum [number] of item edges to process in Criteria Property processing.
						,@InitialOrderLineInstanceStatusValue  = 1000
						,@FirmedOrderLineInstanceStatusValue = 1200
						,@DefaultSARoutingCode  = 15100
						,@WorkOrderStartDateOperationScheduleOffsetMode  = 1 -- Determines the technique used to calculate Operation Schedule Offset Work Order Start Date: [0] - Time Optimized,[1] - Yield Optimized
						,@CLRDebugMode  = default -- Sets flag to produce extended textual processing logging. See CLR SP call below for more.
						,@OutputCLRDebugging  = default -- When CLR Debug Mode is set and this code is run from SQL Server Management Studio, it prints and outputs log.          
			

					--删除前期自定义属性
					DELETE FROM @itmAvTable 
					--添加品项自定义属性
					IF @pageName IN(N'普通顶线')
					BEGIN
						IF @info1 IS NOT NULL AND LEN(LTRIM(@info1))>0
						BEGIN
							INSERT INTO @itmAvTable VALUES(@itmIDNew,115,@info1)
						END
						IF @info2 IS NOT NULL AND LEN(LTRIM(@info2))>0
						BEGIN
							INSERT INTO @itmAvTable VALUES(@itmIDNew,44,@info2)
						END
					END
					--ELSE IF @pageName IN(N'普通背板')
					--BEGIN
					--	IF @info1 IS NOT NULL OR @info2 IS NOT NULL
					--	BEGIN
					--		  INSERT INTO dbo.fxmRuleAnalysis_RJZ_OPP(ordId,itmID,olnID,info2,info3)VALUES(@ordID,@itmIDNew,@olnID,ISNULL(@info1,N''),ISNULL(@info2,N''))
					--	END
					--END

					IF @pageName NOT IN(N'普通顶线',N'木框门芯')
					BEGIN
						IF @info3 IS NOT NULL AND LEN(LTRIM(@info3))>0
						BEGIN
							INSERT INTO @itmAvTable VALUES(@itmIDNew,45,@info3)
						END
					END

					--添加品项自定义属性
					INSERT INTO dbo.ItemAttributeValues( itmID, atbID, itmavValue, aoID )
					SELECT itmID,atbID,itmValue,3 FROM @itmAvTable

					--添加尺寸
					IF NOT(@dimFX IS NULL AND @dimFY IS NULL AND @dimFZ IS NULL)
					BEGIN 
						INSERT INTO dbo.ItemDimensions(itmID, dimID, dimX, dimY, dimZ )
						SELECT @itmIDNew AS itmID,1 AS dimID,ISNULL(@dimFX,0) AS dimX,ISNULL(@dimFY,0) AS dimY,ISNULL(@dimFZ,0) AS dimZ
					END
					IF NOT(@dimCX IS NULL AND @dimCY IS NULL AND @dimCZ IS NULL)
					BEGIN
						INSERT INTO dbo.ItemDimensions(itmID, dimID, dimX, dimY, dimZ )
						SELECT @itmIDNew AS itmID,3 AS dimID,ISNULL(@dimCX,0) AS dimX,ISNULL(@dimCY,0) AS dimY,ISNULL(@dimCZ,0) AS dimZ
					END
					--添加封边
					IF @edgeCode IS NOT NULL AND @edgeCode !=N'0000'
					BEGIN
						DELETE FROM @addOptData
						INSERT INTO @addOptData
						SELECT 
							ROW_NUMBER()OVER(PARTITION BY itme.topSurCode,itme.itmeWidth ORDER BY itme.itmeThickness) AS RowID	--1为薄边，2为厚边
							,itme.itmeThickness
							,itme.surCode
						FROM dbo.ItemEdgesSurCode_OPP itme 
						WHERE itme.TopSurCode=@topSurCode 
								AND CONVERT(decimal(18,0),itme.itmeWidth)=CONVERT(decimal(18,0),@dimFZ)
								AND itme.itmeThickness !=0
						IF @@ROWCOUNT>0
						BEGIN
							DELETE FROM @addEdgeData
							INSERT INTO @addEdgeData
							SELECT 
								itmeEdgeNo
								,edgeThick
							FROM 
							(SELECT 
								cus.edge1 AS [4]
								,cus.edge2 AS [2]
								,cus.edge3 AS [3]
								,cus.edge4 AS [1]
							FROM dbo.CUS_mOrdItemEdgeCode_OPP cus
							WHERE cus.edgeCode=@edgeCode 
								AND cus.sumValue!=0
							)s
							UNPIVOT(edgeThick FOR itmeEdgeNo IN([1],[2],[3],[4]))AS up

							INSERT INTO dbo.ItemEdges(itmID,itmeEdgeNo,surCode,trmID,msqID,opsID,itmeThickness,itmeLength,itmeWidth)
							SELECT 
								@itmIDNew AS itmID
								,aEdge.itmeEdgeNo
								,oEdge.surCode
								,@trmID
								,@msqID
								,@opsID
								,oEdge.itmeThickness
								,(CASE WHEN aEdge.itmeEdgeNo IN(1,3) THEN @dimFX ELSE @dimFY END)AS itmeLength
								,@dimFZ AS itmeWidth
							FROM @addEdgeData aEdge
							JOIN @addOptData oEdge ON oEdge.RowID=aEdge.edgeThick

							INSERT INTO dbo.OrderItemEdges(itmID,itmIDInstance,olnID,olnIDInstance,orieEdgeNo,surCode,trmID,msqID,opsID,orieLength,orieWidth,orieThickness)
							SELECT 
								@itmIDNew AS itmID
								,1 AS itmIDInstance
								,@olnID AS olnID
								,@olnIDInstance AS olnIDInstance
								,aEdge.itmeEdgeNo
								,oEdge.surCode
								,@trmID
								,@msqID
								,@opsID
								,oEdge.itmeThickness
								,(CASE WHEN aEdge.itmeEdgeNo IN(1,3) THEN @dimFX ELSE @dimFY END)AS itmeLength
								,@dimFZ AS itmeWidth
							FROM @addEdgeData aEdge
							JOIN @addOptData oEdge ON oEdge.RowID=aEdge.edgeThick
						END
						ELSE
						BEGIN
							SET @errMsg= N'花色:'+@topSurCode+N' 封边宽：'+CAST(@dimFZ AS NVARCHAR(10))+N',不存在面材代码'
							RAISERROR(@errMsg,16,1);
							RETURN
						END
					END
			
					IF @pageName IN(N'普通顶线',N'木框门芯')
					BEGIN
						DELETE FROM @mrTable
						INSERT INTO @mrTable( RowID,itmID ,itmIDInstance ,olnID ,olnIDInstance ,topSurCode ,corCode ,botSurCode )
						SELECT TOP 1
								tb.RowID
								,@itmIDNew AS itmID
								,1 AS itmIDInstance
								,@olnID AS olnID
								,@olnIDInstance
								,tb.TopSurCode
								,tb.corCode
								,tb.BotSurCode
						FROM (SELECT TOP 1 
									1 AS RowID
									,itmm.TopSurCode
									,itmm.corCode
									,itmm.BotSurCode
							FROM dbo.MaterialSourceItems itmm 
							JOIN dbo.Items itm ON itm.itmID = itmm.itmID
							WHERE itm.itmDescription2=@info3
							UNION ALL
							SELECT TOP 1
								2 AS RowID
								,mr.TopSurCode
								,mr.corCode
								,mr.BotSurCode
							FROM dbo.Materials mr
							WHERE mr.matDescription=@info3
						)tb ORDER BY tb.RowID

						INSERT INTO dbo.ItemMaterials(itmID,TopSurCode,corCode,BotSurCode)
						SELECT itmID,TopSurCode,corCode,BotSurCode FROM @mrTable

						INSERT INTO dbo.OrderItemMaterials(itmID,itmIDInstance,olnID,olnIDInstance,TopSurCode,corCode,BotSurCode)
						SELECT itmID,itmIDInstance,olnID,olnIDInstance,TopSurCode,corCode,BotSurCode FROM @mrTable
					END

					--添加材料
					IF @topSurCode IS NOT NULL AND @corCode IS NOT NULL
					BEGIN 
						IF NOT EXISTS(SELECT 1 FROM Materials mat WHERE mat.TopSurCode=@topSurCode AND mat.BotSurCode=@topSurCode AND mat.corCode=@corCode)
						BEGIN
							SET @errMsg= N'顶材:'+@topSurCode+N' 芯材：'+@corCode+N' 底材:'+@topSurCode+N'材料表中不存在，请先添加该材料！'
							RAISERROR(@errMsg,16,1);
						END
						ELSE
						BEGIN
							INSERT INTO dbo.ItemMaterials(itmID,TopSurCode,corCode,BotSurCode)VALUES(@itmIDNew,@topSurCode,@corCode,@topSurCode)

							INSERT INTO dbo.OrderItemMaterials(itmID,itmIDInstance,olnID,olnIDInstance,TopSurCode,corCode,BotSurCode)
							VALUES(@itmIDNew,1,@olnID,1,@topSurCode,@corCode,@topSurCode)
						END
					END

					--添加备注
					IF NOT(@info5 IS NULL AND @info6 IS NULL AND @info14 IS NULL AND @info15 IS NULL AND @Factory IS NULL AND @Duty IS NULL AND @PlateCategory IS NULL AND @LegacyPrice IS NULL)
					BEGIN
						INSERT INTO dbo.hole_analysis(ordID,itmID,newdmRemark,holeRemark,Remark,WenLu,Factory,Duty,PlateCategory,LegacyPrice)
						VALUES(@ordID,@itmIDNew,@info14,@info15,@info6,@info5,@Factory,@Duty,@PlateCategory,@LegacyPrice)
					END
					--添加原始数据
					INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,actions,itmIDSA,dlCode,oriReqQty
						,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,topSurCode,corCode,edgeCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1,info2,info3,info5,info6,info14,info15)
					SELECT @ordID,@pageName,@itmIDNew,1,@OlnID,1,@itmID,@itmIDInstance,2,@itmIDSA,@dlCode,@oriReqQty,@primaryUOMCode,@newItmItemNumber,@newItmDescription
						,@itmfCode,@topSurCode,@corCode,@edgeCode,@dimCX,@dimCY,@dimCZ,@dimFX,@dimFY,@dimFZ,@info1,@info2,@info3,@info5,@info6,@info14,@info15

					--添加日志
					INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,actions,itmDescription,itmfCode,topSurCode,corCode,edgeCode
							,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1,info2,info3,info5,info6,info14,info15,Factory,Duty,PlateCategory,LegacyPrice,createdOn,createdBy)
					SELECT @ordID,@pageName,@itmIDNew,1,@OlnID,1,@oriReqQty,2,@newItmDescription,@itmfCode,@topSurCode,@corCode,@edgeCode
							,@dimCX,@dimCY,@dimCZ,@dimFX,@dimFY,@dimFZ,@info1,@info2,@info3,@info5,@info6,@info14,@info15,@Factory,@Duty,@PlateCategory,@LegacyPrice,GETDATE(),USER_NAME()
			
					SET @While+=1;
				END
			END
			--操作后数据删除
			DELETE FROM @addBOMData

			--三、修改操作（数据执行）
			--3.1、修改BOM数量（板件不允许修改数量）
			--3.3、修改品项描述
			;WITH itmT AS
			(
				SELECT itmID
					,MAX(itmDescription) AS itmDescription 
				FROM @YLOrdItmTable 
				WHERE actions=4 
				GROUP BY itmID
			)
			UPDATE s SET s.itmDescription = t.itmDescription
			FROM itmT t
			JOIN dbo.Items s ON s.itmID = t.itmID
			WHERE t.itmDescription IS NOT NULL
				AND t.itmDescription != s.itmDescription

			--3.4、修改尺寸
			--批量修改
			MERGE INTO dbo.ItemDimensions dim
			USING @itmDimTable U ON U.itmID = dim.itmID AND U.dimID=dim.dimID
			WHEN MATCHED THEN UPDATE SET dim.dimX=U.dimX,dim.dimY=U.dimY,dim.dimz=U.dimZ
			WHEN NOT MATCHED THEN INSERT(itmID,dimID,dimX,dimY,dimZ)
				VALUES(U.itmID,U.dimID,U.dimX,U.dimY,U.dimZ);

			--3.5、处理品项体系数据
			UPDATE s SET s.itmfCode = YLOrd.itmfCode
			FROM @YLOrdItmTable YLOrd 
			JOIN dbo.ItemItemFamilies s ON s.itmID=YLOrd.itmID
			WHERE YLOrd.actions=4
				AND YLOrd.itmfCode IS NOT NULL
				AND s.itmfCode!=YLOrd.itmfCode

			--3.6 芯材处理，判断材料是否存在
			SELECT TOP 1 @errMsg =N'顶材:'+YLOrd.topSurCode+N' 芯材：'+YLOrd.corCode+N' 底材:'+YLOrd.topSurCode 
			FROM @YLOrdItmTable YLOrd
			LEFT JOIN dbo.Materials mat ON mat.corCode = YLOrd.corCode 
				AND mat.TopSurCode = YLOrd.topSurCode 
				AND mat.BotSurCode = YLOrd.topSurCode
			WHERE YLOrd.actions=4 
				AND YLOrd.corCode IS NOT NULL 
				AND YLOrd.topSurCode IS NOT NULL 
				AND mat.corCode IS NULL
			IF @errMsg IS NOT NULL
			BEGIN
				SET @errMsg+=N' 材料表中不存在，请先添加该材料！'
				RAISERROR(@errMsg,16,1);
			END
			ELSE
			BEGIN
				MERGE INTO dbo.ItemMaterials T
				USING
				(
					SELECT 
						tb.itmID
						,tb.topSurCode
						,tb.corCode
						,tb.topSurCode AS BotSurCode
					FROM
					(SELECT 
						ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID ORDER BY YLOrd.topSurCode)AS RowID
						,YLOrd.itmID
						,YLOrd.topSurCode
						,YLOrd.corCode
					FROM @YLOrdItmTable YLOrd
					WHERE YLOrd.actions=4 
						AND YLOrd.itmID IS NOT NULL
						AND YLOrd.corCode IS NOT NULL
						AND YLOrd.topSurCode IS NOT NULL
					)tb WHERE tb.RowID=1
						AND NOT EXISTS(SELECT 1 FROM dbo.ItemMaterials s(NOLOCK)WHERE s.itmID=tb.itmID AND s.TopSurCode=tb.topSurCode AND s.corCode=tb.corCode AND s.BotSurCode=tb.topSurCode)
				)U ON U.itmID=T.itmID
				WHEN MATCHED THEN UPDATE SET T.corCode =U.corCode,T.TopSurCode=U.topSurCode,T.BotSurCode=U.topSurCode
				WHEN NOT MATCHED THEN INSERT(itmID,TopSurCode,corCode,BotSurCode)VALUES(U.itmID,U.topSurCode,U.corCode,U.BotSurCode);

				MERGE INTO dbo.OrderItemMaterials T
				USING
				(
					SELECT 
						tb.itmID
						,tb.itmIDInstance
						,tb.olnID
						,tb.olnIDInstance
						,tb.topSurCode
						,tb.corCode
						,tb.topSurCode AS BotSurCode
					FROM
					(SELECT 
						ROW_NUMBER()OVER(PARTITION BY YLOrd.itmID,YLOrd.itmIDInstance,YLOrd.olnID,YLOrd.olnIDInstance ORDER BY YLOrd.topSurCode)AS RowID
						,YLOrd.itmID
						,YLOrd.itmIDInstance
						,YLOrd.olnID
						,YLOrd.olnIDInstance
						,YLOrd.topSurCode
						,YLOrd.corCode
					FROM @YLOrdItmTable YLOrd
					WHERE YLOrd.actions=4
						AND YLOrd.itmID IS NOT NULL
						AND YLOrd.itmIDInstance IS NOT NULL
						AND YLOrd.olnID IS NOT NULL
						AND YLOrd.olnIDInstance IS NOT NULL
						AND YLOrd.corCode IS NOT NULL
						AND YLOrd.topSurCode IS NOT NULL
					
					)tb WHERE tb.RowID=1
						AND NOT EXISTS(SELECT 1 FROM dbo.OrderItemMaterials s(NOLOCK)WHERE s.itmID=tb.itmID AND s.itmIDInstance=tb.itmIDInstance AND s.olnID=tb.olnID 
										AND s.olnIDInstance=tb.olnIDInstance AND s.TopSurCode=tb.topSurCode AND s.corCode=tb.corCode AND s.BotSurCode=tb.topSurCode)
				)U ON U.itmID=T.itmID AND U.itmIDInstance=T.itmIDInstance AND U.olnID=T.olnID AND U.olnIDInstance=T.olnIDInstance
				WHEN MATCHED THEN UPDATE SET T.corCode =U.corCode,T.TopSurCode=U.topSurCode,T.BotSurCode=U.topSurCode
				WHEN NOT MATCHED THEN INSERT(itmID,itmIDInstance,olnID,olnIDInstance,TopSurCode,corCode,BotSurCode)
				VALUES(U.itmID,U.itmIDInstance,U.olnID,U.olnIDInstance,U.topSurCode,U.corCode,U.BotSurCode);
			END

			--3.7 处理封边(封边1与封边4互换)
			--修改封边
			MERGE INTO dbo.ItemEdges itme
			USING(
				SELECT edge.itmID
					,edge.itmeEdgeNo
					,edge.surCode
					,edge.itmeLength
					,edge.itmeWidth
					,edge.edgeThick 
				FROM @edgeData edge
				GROUP BY edge.itmID
					,edge.itmeEdgeNo
					,edge.surCode
					,edge.itmeLength
					,edge.itmeWidth
					,edge.edgeThick
			)U ON itme.itmID=U.itmID AND itme.itmeEdgeNo=u.itmeEdgeNo
			WHEN MATCHED THEN UPDATE SET itme.surCode=U.surCode,itme.itmeThickness=U.edgeThick
			WHEN NOT MATCHED THEN INSERT(itmID,itmeEdgeNo,surCode,trmID,msqID,opsID,itmeLength,itmeWidth,itmeThickness)
				VALUES(U.itmID,U.itmeEdgeNo,U.surCode,@trmID,@msqID,@opsID,U.itmeLength,U.itmeWidth,U.edgeThick);

			MERGE INTO dbo.OrderItemEdges orie
			USING @edgeData U ON orie.itmID=U.itmID AND orie.orieEdgeNo=u.itmeEdgeNo
			WHEN MATCHED THEN UPDATE SET orie.surCode=U.surCode,orie.orieThickness=U.edgeThick
			WHEN NOT MATCHED THEN INSERT(itmID,itmIDInstance,olnID,olnIDInstance,orieEdgeNo,surCode,trmID,msqID,opsID,orieLength,orieWidth,orieThickness)
				VALUES(U.itmID,U.itmIDInstance,U.olnID,U.olnIDInstance,U.itmeEdgeNo,U.surCode,@trmID,@msqID,@opsID,U.itmeLength,U.itmeWidth,U.edgeThick);

			--若修改为无封边，则删除封边
			DELETE s
			FROM @YLOrdItmTable YLOrd
			JOIN dbo.ItemEdges s(NOLOCK) ON s.itmID = YLOrd.itmID
			WHERE YLOrd.actions=4
				AND YLOrd.itmID IS NOT NULL
				AND (YLOrd.edgeCode IS NULL OR YLOrd.edgeCode=N'0000')

			DELETE s
			FROM @YLOrdItmTable YLOrd
			JOIN dbo.OrderItemEdges s(NOLOCK) ON s.itmID = YLOrd.itmID
			WHERE YLOrd.actions=4
				AND YLOrd.itmID IS NOT NULL
				AND (YLOrd.edgeCode IS NULL OR YLOrd.edgeCode=N'0000')	
			
			--3.8 添加备注
			MERGE INTO dbo.hole_analysis T
			USING
			(
				SELECT 
					@ordID AS ordID
					,YLOrd.itmID
					,YLOrd.info5
					,YLOrd.info6
					,CASE WHEN ISNUMERIC(YLOrd.info7)=1 THEN CAST(YLOrd.info7 AS FLOAT) END AS info7
					,YLOrd.info8
					,CASE WHEN ISNUMERIC(YLOrd.info9)=1 THEN CAST(YLOrd.info9 AS FLOAT) END AS info9
					,CASE WHEN ISNUMERIC(YLOrd.info10)=1 THEN CAST(YLOrd.info10 AS FLOAT) END AS info10
					,CASE WHEN ISNUMERIC(YLOrd.info11)=1 THEN CAST(YLOrd.info11 AS FLOAT) END AS info11
					,CASE WHEN ISNUMERIC(YLOrd.info12)=1 THEN CAST(YLOrd.info12 AS FLOAT) END AS info12
					,CASE WHEN ISNUMERIC(YLOrd.info13)=1 THEN CAST(YLOrd.info13 AS FLOAT) END AS info13
					,YLOrd.info14
					,YLOrd.info15
					,YLOrd.Factory
					,YLOrd.Duty
					,YLOrd.PlateCategory
					,YLOrd.LegacyPrice
				FROM @YLOrdItmTable YLOrd 
				WHERE YLOrd.actions=4
					AND NOT EXISTS(SELECT 1 FROM dbo.hole_analysis ha (NOLOCK)
							WHERE ha.ordID=@ordID AND ha.itmID=YLOrd.itmID AND ISNULL(ha.hole,0)=ISNULL(YLOrd.info7,0) AND ISNULL(ha.holedis,N'')=ISNULL(YLOrd.info8,N'')
								AND ISNULL(ha.newdm1,0)=ISNULL(YLOrd.info9,0) AND ISNULL(ha.newdm2,0)=ISNULL(YLOrd.info10,0) AND ISNULL(ha.newdm3,0)=ISNULL(YLOrd.info11,0)
								AND ISNULL(ha.newdm4,0)=ISNULL(YLOrd.info12,0) AND ISNULL(ha.newdm5,0)=ISNULL(YLOrd.info13,0) AND ISNULL(ha.newdmRemark,N'')=ISNULL(YLOrd.info14,N'')
								AND ISNULL(ha.holeRemark,N'')=ISNULL(YLOrd.info15,N'')AND ISNULL(ha.Remark,N'')=ISNULL(YLOrd.info6,N'')AND ISNULL(ha.WenLu,N'')=ISNULL(YLOrd.info5,N'')
								AND ISNULL(ha.Factory,N'')=ISNULL(YLOrd.Factory,N'') AND ISNULL(ha.Duty,N'')=ISNULL(YLOrd.Duty,N'') AND ISNULL(ha.PlateCategory,N'')=ISNULL(YLOrd.PlateCategory,N'')
								AND ISNULL(ha.LegacyPrice,0)=ISNULL(YLOrd.LegacyPrice,0)
					)
			)U ON U.ordID=T.ordID AND U.itmID=T.itmID
			WHEN NOT MATCHED THEN INSERT(ordID,itmID,hole,holedis,newdm1,newdm2,newdm3,newdm4,newdm5,newdmRemark,holeRemark,Remark,WenLu,Factory,Duty,PlateCategory,LegacyPrice)
				VALUES(U.ordID,U.itmID,U.info7,U.info8,U.info9,U.info10,U.info11,U.info12,U.info13,U.info14,U.info15,U.info6,U.info5,U.Factory,U.Duty,U.PlateCategory,U.LegacyPrice)
			WHEN MATCHED THEN UPDATE SET T.hole=U.info7,T.holedis=U.info8,T.newdm1=U.info9,T.newdm2=U.info10,T.newdm3=U.info11,T.newdm4=U.info12,T.newdm5=U.info13,T.newdmRemark=U.info14
				,T.holeRemark=U.info15,T.Remark=U.info6,T.WenLu=U.info5,T.Factory=U.Factory,T.Duty=U.Duty,T.PlateCategory=U.PlateCategory,T.LegacyPrice=U.LegacyPrice;
		
			--3.9 添加与修改（自定义属性）
			MERGE INTO dbo.ItemAttributeValues itmAv
			USING(
				SELECT * FROM @itmAvTable WHERE LEN(LTRIM(itmValue))>0
			)U ON itmAv.itmID=U.itmID AND itmAv.atbID=U.atbID
			WHEN MATCHED THEN UPDATE SET itmAv.itmavValue= U.itmValue
			WHEN NOT MATCHED THEN INSERT(itmID,atbID,itmavValue,aoID)VALUES(U.itmID,U.atbID,U.itmValue,3);
			--删除
			DELETE s 
			FROM @itmAvTable itmAv
			JOIN dbo.ItemAttributeValues s ON itmAv.itmID=s.itmID AND itmAv.atbID=s.atbID
			WHERE LEN(LTRIM(itmAv.itmValue))=0

			--3.10 info3 为普通顶线\木框门芯 材料
			--根据Info3获取芯材与花色
			MERGE INTO dbo.ItemMaterials s
			USING(
				SELECT * 
				FROM @mrTable mOrd 
				WHERE mOrd.itmRowID=1
			)U ON s.itmID=U.itmID
			WHEN MATCHED THEN UPDATE SET s.corCode =U.corCode,TopSurCode=U.topSurCode,BotSurCode=U.botSurCode
			WHEN NOT MATCHED THEN INSERT(itmID,TopSurCode,corCode,BotSurCode)VALUES(U.itmID,U.topSurCode,U.corCode,U.botSurCode);

			MERGE INTO OrderItemMaterials s
			USING(
				SELECT * FROM @mrTable mOrd WHERE mOrd.RowID=1
			)U ON s.itmID=U.itmID
				AND s.itmIDInstance=U.itmIDInstance
				AND s.olnID=U.olnID
				AND s.olnIDInstance=U.olnIDInstance
			WHEN MATCHED THEN UPDATE SET s.corCode =U.corCode,TopSurCode=U.topSurCode,BotSurCode=U.botSurCode
			WHEN NOT MATCHED THEN INSERT(itmID,itmIDInstance,olnID,olnIDInstance,TopSurCode,corCode,BotSurCode)
				VALUES(U.itmID,U.itmIDInstance,U.olnID,U.olnIDInstance,U.topSurCode,U.corCode,U.botSurCode);
		
			--3.11、修改特征 
			DECLARE @Info1_ID INT=1371,@Info2_ID INT=1383,@Info4_ID INT;	--1371 下门芯,1383 上门芯,983 UT50_85 门板工艺
			IF @pageName IN(N'吸塑门')
			BEGIN
				SET @Info4_ID =983;		--983 UT50_85 门板工艺
			END
			MERGE INTO dbo.OrderLineOptions olno
			USING(
				SELECT 
					YLOrd.olnID
					,MAX(fo.optID) AS optID
					,@Info1_ID AS ftrID
				FROM @YLOrdItmTable YLOrd
				JOIN Product.FeatureOptions fo(NOLOCK) ON fo.ftrID=@Info1_ID 
				JOIN Product.Options opt(NOLOCK) ON opt.optID = fo.optID AND opt.optDescription=YLOrd.info1
				WHERE YLOrd.actions=4
					AND @pageName IN(N'吸塑门')
					AND @ordSource!=N'CAD'
					AND @Info1_ID IS NOT NULL
					AND YLOrd.info1 IS NOT NULL
					AND LEN(RTRIM(YLOrd.info1))>0
				GROUP BY YLOrd.olnID
				UNION ALL
				SELECT 
					YLOrd.olnID
					,MAX(fo.optID) AS optID
					,@Info2_ID AS ftrID
				FROM @YLOrdItmTable YLOrd
				JOIN Product.FeatureOptions fo(NOLOCK) ON fo.ftrID=@Info2_ID 
				JOIN Product.Options opt(NOLOCK) ON opt.optID = fo.optID AND opt.optDescription = YLOrd.info2
				WHERE YLOrd.actions=4
					AND @pageName IN(N'吸塑门')
					AND @ordSource !=N'CAD'
					AND @Info2_ID IS NOT NULL
					AND YLOrd.info2 IS NOT NULL
					AND LEN(RTRIM(YLOrd.info2))>0
				GROUP BY YLOrd.olnID
				UNION ALL
				SELECT 
					YLOrd.olnID
					,MAX(fo.optID) AS optID
					,@Info4_ID AS ftrID
				FROM @YLOrdItmTable YLOrd
				JOIN Product.FeatureOptions fo(NOLOCK) ON fo.ftrID=@Info4_ID
				JOIN Product.Options opt(NOLOCK) ON opt.optID = fo.optID AND opt.optDescription = YLOrd.info4 
				WHERE YLOrd.actions=4
					AND @Info4_ID IS NOT NULL
					AND YLOrd.info4 IS NOT NULL
					AND LEN(RTRIM(YLOrd.info4))>0
				GROUP BY YLOrd.olnID
			)U ON U.olnID=olno.olnID AND U.ftrID=olno.ftrID
			WHEN MATCHED THEN UPDATE SET olno.optID=U.optID
			WHEN NOT MATCHED THEN INSERT(olnID,optID,ftrID,optoID,olnoFeatureHidden,olnoIsEditable,olosID)
				VALUES(U.olnID,U.optID,U.ftrID,4,0,1,4);
			--普通背板(暂时注释)
			MERGE INTO dbo.fxmRuleAnalysis_RJZ_OPP T
			USING(SELECT 
					@ordID AS OrdID
					,YLOrd.olnID
					,YLOrd.itmID
					,YLOrd.info1
					,YLOrd.info2
				FROM @YLOrdItmTable YLOrd
				WHERE YLOrd.actions=4
					AND @pageName =N'普通背板'
					AND NOT(YLOrd.info1 IS NULL AND YLOrd.info2 IS NULL)
			)U ON T.itmID=U.itmID AND T.olnID=U.olnID AND T.ordID=U.ordID
			WHEN MATCHED THEN UPDATE SET T.info2=U.info1,T.info3=U.info2
			WHEN NOT MATCHED THEN INSERT(ordId,itmID,olnID,info2,info3)VALUES(U.ordID,U.itmID,U.olnID,U.info1,U.info2);

			--四、 更新原始表的更改状态
			UPDATE s SET s.actions=YLOrd.actions
			FROM @YLOrdItmTable YLOrd
			JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] s ON s.itmID=YLOrd.itmID
				AND s.itmIDInstance=YLOrd.itmIDInstance
				AND s.olnID=YLOrd.olnID
				AND s.olnIDInstance=YLOrd.olnIDInstance
			WHERE YLOrd.actions IN(3,4)
				AND s.actions !=2
			--五、日志记录
			INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,actions,itmDescription,itmfCode,topSurCode,corCode,edgeCode
					,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1,info2,info3,info4,info5,info6,info7,info8,info9,info10,info11,info12,info13,info14,info15,Factory,Duty,PlateCategory,LegacyPrice,createdOn,createdBy)
			SELECT 
				@ordID AS ordID
				,@pageName AS pageName
				,YLOrd.itmID
				,YLOrd.itmIDInstance
				,YLOrd.olnID
				,YLOrd.olnIDInstance
				,YLOrd.oriReqQty
				,YLOrd.actions
				,YLOrd.itmDescription
				,YLOrd.itmfCode
				,YLOrd.topSurCode
				,YLOrd.corCode
				,YLOrd.edgeCode
				,YLOrd.dimCX
				,YLOrd.dimCY
				,YLOrd.dimCZ
				,YLOrd.dimFX
				,YLOrd.dimFY
				,YLOrd.dimFZ
				,YLOrd.info1
				,YLOrd.info2
				,YLOrd.info3
				,YLOrd.info4
				,YLOrd.info5
				,YLOrd.info6
				,YLOrd.info7
				,YLOrd.info8
				,YLOrd.info9
				,YLOrd.info10
				,YLOrd.info11
				,YLOrd.info12
				,YLOrd.info13
				,YLOrd.info14
				,YLOrd.info15
				,YLOrd.Factory
				,YLOrd.Duty
				,YLOrd.PlateCategory
				,YLOrd.LegacyPrice
				,GETDATE()
				,USER_NAME()
			FROM @YLOrdItmTable YLOrd
			WHERE YLOrd.actions IN(3,4)
			
			-- 六、汇总信息
			IF EXISTS(SELECT TOP 1 1 FROM @YLOrdTotalTable)
			BEGIN
				--删除当前页签数据
				DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID AND PageName=@pageName
				--
				MERGE INTO [dbo].[CUS_YLOrdPagesTotalData_OPP] T
				USING(
					SELECT @ordID AS ordID
						,PageName
						,PlateCategory
						,TotalPrice 
					FROM @YLOrdTotalTable
				)U ON T.OrdID=U.ordID AND T.PageName=U.PageName AND T.PlateCategory=U.PlateCategory
				WHEN MATCHED THEN UPDATE SET T.TotalPrice=U.TotalPrice
				WHEN NOT MATCHED THEN INSERT(OrdID,PageName,PlateCategory,TotalPrice)
					VALUES(U.ordID,U.PageName,U.PlateCategory,U.TotalPrice);
		
				--添加汇总日志
				INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,PageName,PlateCategory,TotalPrice,CreatedOn,CreatedBy)
				SELECT @ordID AS ordID
						,PageName
						,PlateCategory
						,TotalPrice
						,GETDATE() AS CreatedOn
						,SYSTEM_USER AS CreatedBy
				FROM @YLOrdTotalTable
			END
			ELSE
			BEGIN
				--删除当前页签数据
				DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID
				--添加汇总日志
				INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,CreatedOn,CreatedBy)
				SELECT @ordID AS ordID,GETDATE() AS CreatedOn,SYSTEM_USER AS CreatedBy FROM @YLOrdTotalTable
			END
			--5、更新主材料(暂时注释)
			--EXEC spApp_utlAssignMainMaterialAndMfgArea_OPP @ordID=@ordID

			--提交事务
			COMMIT TRANSACTION;
		END
	END
END
ELSE
BEGIN
	BEGIN TRY
		-- 开启事务
		BEGIN TRANSACTION
		IF EXISTS(SELECT TOP 1 1 FROM @YLOrdTotalTable)
		BEGIN
			--删除当前页签数据
			DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID AND PageName=@pageName
			--
			MERGE INTO [dbo].[CUS_YLOrdPagesTotalData_OPP] T
			USING(
				SELECT @ordID AS ordID
					,PageName
					,PlateCategory
					,TotalPrice 
				FROM @YLOrdTotalTable
			)U ON T.OrdID=U.ordID AND T.PageName=U.PageName AND T.PlateCategory=U.PlateCategory
			WHEN MATCHED THEN UPDATE SET T.TotalPrice=U.TotalPrice
			WHEN NOT MATCHED THEN INSERT(OrdID,PageName,PlateCategory,TotalPrice)
				VALUES(U.ordID,U.PageName,U.PlateCategory,U.TotalPrice);
		
			--添加汇总日志
			INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,PageName,PlateCategory,TotalPrice,CreatedOn,CreatedBy)
			SELECT @ordID AS ordID
					,PageName
					,PlateCategory
					,TotalPrice
					,GETDATE() AS CreatedOn
					,SYSTEM_USER AS CreatedBy
			FROM @YLOrdTotalTable
		END
		ELSE
		BEGIN
			--删除当前页签数据
			DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID
			--添加汇总日志
			INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,CreatedOn,CreatedBy)
			SELECT @ordID AS ordID,GETDATE() AS CreatedOn,SYSTEM_USER AS CreatedBy FROM @YLOrdTotalTable
		END
		--提交事务
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		DECLARE @msg nvarchar(200)=ERROR_MESSAGE()    --将捕捉到的错误信息存在变量@msg中               
		RAISERROR (@msg,16,1)    --此处才能抛出(好像是这样子....)
		--回滚事务
		ROLLBACK TRANSACTION
	END CATCH
END
