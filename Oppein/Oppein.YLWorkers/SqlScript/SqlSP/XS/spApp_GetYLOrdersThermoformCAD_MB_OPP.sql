﻿
ALTER PROC [dbo].[spApp_GetYLOrdersThermoformCAD_MB_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)=N'吸塑门'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

DECLARE @PlateCategory NVARCHAR(50)
SELECT @PlateCategory=PlateCategory FROM [dbo].[CUS_YLOrdPagesData_OPP] WHERE PageName=@pageName
SELECT @Factory=FactoryDefualt FROM [dbo].[CUS_YLOrdPageFactoryDefualt_OPP] WHERE Factory=@Factory AND PageName=@pageName 
--判断原始表数据是否存在(若存则关联，若不存在则插入)
IF EXISTS(SELECT 1 FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] WHERE ordId=@ordID AND pageName=@pageName)
BEGIN
	;WITH T AS
	(
		SELECT 
			oln.olnLineNo 
			,ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	SELECT 
		t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		--,t.itmIDParent
		--,t.itmIDParentInstance
		--,t.olnLineNo
		,t.itmItemNumber
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty
		--,t.PrimaryUOMCode
		,SA.itmID AS itmIDSA
		,SA.itmDescription AS itmDescriptionSA
		,t.itmDescription
		,ISNULL(org.itmDescription,t.itmDescription) AS oItmDescription
		,oriMat.TopSurCode AS topSurCode
		,ISNULL(org.topSurCode,oriMat.TopSurCode) AS oTopSurCode
		,oriMat.corCode
		,ISNULL(org.corCode,oriMat.corCode) AS oCorCode
		,CAST((case when itmAv.info3 like N'%翻%' then oDim.dimCX else oDim.dimCY END) AS FLOAT) AS dimCY
		,CAST((CASE WHEN itmAv.info3 like N'%翻%' THEN ISNULL(org.dimCX,oDim.dimCX) ELSE ISNULL(org.dimCY,oDim.dimCY) END)AS FLOAT) AS oDimCY
		,CAST((case when itmAv.info3 like N'%翻%' then oDim.dimCY else oDim.dimCX END) AS FLOAT) AS dimCX
		,CAST((CASE WHEN itmAv.info3 like N'%翻%' THEN ISNULL(org.dimCY,oDim.dimCY) ELSE ISNULL(org.dimCX,oDim.dimCX) END)AS FLOAT) AS oDimCX
		--,CAST(oDim.dimCX AS FLOAT) AS dimCX
		--,CAST(ISNULL(org.dimCX,oDim.dimCX) AS FLOAT) AS oDimCX
		--,CAST(oDim.dimCY AS FLOAT) AS dimCY
		--,CAST(ISNULL(org.dimCY,oDim.dimCY) AS FLOAT) AS oDimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(ISNULL(org.dimCZ,oDim.dimCZ) AS FLOAT) AS oDimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(ISNULL(org.dimFX,oDim.dimFX) AS FLOAT) AS oDimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(ISNULL(org.dimFY,oDim.dimFY) AS FLOAT) AS oDimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,CAST(ISNULL(org.dimFZ,oDim.dimFZ) AS FLOAT) AS oDimFZ
		,ISNULL(cEdge.edgeCode,N'0000') AS edgeCode
		,ISNULL(org.edgeCode,N'0000') AS oEdgeCode
		,org.actions
		,(CASE WHEN itmAv.info4 not like N'%/%' then itmAv.info4 else substring(itmAv.info4,1,charindex('/',itmAv.info4)-1) END) info1	--下门芯
		,case when itmAv.info4 like N'%/%' then substring(itmAv.info4,charindex('/',itmAv.info4)+1,len(itmAv.info4)) end info2	--上门芯
		,itmAv.info3
		,ISNULL(ha.WenLu,CASE when itmAv.info3 like N'%翻%' then N'横纹' else N'竖纹' END) AS info5
		,ISNULL(ha.Remark,itmAv.info1)AS info6
		,ha.hole	AS info7	
		,ha.holedis	AS info8
		,ha.newdm1	AS info9
		,ha.newdm2	AS info10
		,ha.newdm3	AS info11
		,ha.newdm4	AS info12
		,ha.newdm5	AS info13
		,ha.newdmRemark AS info14
		,ha.holeRemark AS info15
		,CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3)) AS cArea
		,(CASE WHEN org.dimCX IS NOT NULL THEN CAST(org.dimCX*org.dimCY/1000000 AS DECIMAL(18,3))
			ELSE CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3)) END) AS oCArea
		,CAST(oDim.dimFX*oDim.dimFY/100000 AS DECIMAL(18,2)) AS Area
		,(CASE WHEN org.dimFX IS NOT NULL THEN CAST(org.dimFX*org.dimFY/100000 AS DECIMAL(18,2))
			ELSE CAST(oDim.dimFX*oDim.dimFY/100000 AS DECIMAL(18,2)) END) AS oArea
		,ISNULL(org.info4,case when itmAv.info4 not like N'%/%' then itmAv.info4 else substring(itmAv.info4,1,charindex('/',itmAv.info4)-1) END) AS oInfo1
		,ISNULL(org.info1,case when itmAv.info4 like N'%/%' then substring(itmAv.info4,charindex('/',itmAv.info4)+1,len(itmAv.info4)) end) AS oInfo2
		,ISNULL(org.info3,itmAv.info3) AS oInfo3
		,COALESCE(org.info5,ha.WenLu,case when itmAv.info3 like N'%翻%' then N'横纹' else N'竖纹' END) AS oInfo5
		,COALESCE(org.info6,ha.Remark,itmAv.info1)AS oInfo6
		,ha.hole AS oInfo7
		,ha.holedis AS oInfo8
		,ha.newdm1 AS oInfo9
		,ha.newdm2 AS oInfo10
		,ha.newdm3 AS oInfo11
		,ha.newdm4 AS oInfo12
		,ha.newdm5 AS oInfo13
		,ha.newdmRemark AS oInfo14
		,ha.holeRemark AS oInfo15
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price		--单价
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
		--,CAST(ISNULL(ha.LegacyPrice,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))) AS FLOAT) AS LegacyPrice		--总价
		--,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode in(N'OSDOOR',N'OSDOOR_BL') 
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
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
		WHERE  t.itmID=orie.itmID 
			AND t.itmIDInstance=orie.itmIDInstance
			AND t.olnID=orie.olnID 
			AND t.olnIDInstance=orie.olnIDInstance  
			AND orie.surCode<>N'No Edge Application'  
			AND atb.atbCode=N'Edge_Thickness_Code' 
			AND atbc.atbcCode=N'Item Info'
	) iatb
	LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge (NOLOCK) ON cEdge.edge1=iatb.Edge1
		AND cEdge.edge2=iatb.Edge2
		AND cEdge.edge3=iatb.Edge3
		AND cEdge.edge4=iatb.Edge4
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	--LEFT JOIN dbo.ItemAttributeValues itmAv (NOLOCK) ON t.itmID=itmAv.itmID AND itmAv.atbID=362
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	/*获取品项的自定义属性*/
	outer apply(
		select
			max(case when iav.atbID=44 then iav.itmavValue end) info1   --备注
			,max(case when iav.atbID=45 then iav.itmavValue end) info3  --开门方向
			,max(case when iav.atbID=115 and iav.itmavValue not in ('STANDARD','-') then iav.itmavValue end) info4 --门芯
		from dbo.ItemAttributeValues iav
		where iav.itmID=t.itmID
			and iav.atbID in (45,44,115)    ---44 ItemInfo2 ,45 ItemInfo3,115 Info1
	)itmAv
	WHERE t.dlCode=N'MA'
	ORDER BY itmItemF.itmfCode ,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

END
ELSE
BEGIN
	;WITH T AS
	(
		SELECT 
			oln.olnLineNo 
			,ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,topSurCode,corCode,edgeCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1,info2,info3,info5,info6)
	SELECT 
		@ordID AS ordID
		,@pageName AS pageName
		,t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmIDParent
		,t.itmIDParentInstance
		,sa.itmID
		,sa.itmDescription AS itmDescriptionSA
		,t.dlCode
		,t.oriReqQty
		,t.PrimaryUOMCode
		,t.itmItemNumber
		,t.itmDescription
		,itmItemF.itmfCode
		,oriMat.TopSurCode AS topSurCode
		,oriMat.corCode
		,ISNULL(cEdge.edgeCode,N'0000') AS edgeCode
		,CAST((case when itmAv.info3 like N'%翻%' then oDim.dimCY else oDim.dimCX END) AS FLOAT) AS dimCX
		,CAST((case when itmAv.info3 like N'%翻%' then oDim.dimCX else oDim.dimCY END) AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,(CASE WHEN itmAv.info4 not like N'%/%' then itmAv.info4 else substring(itmAv.info4,1,charindex('/',itmAv.info4)-1) END) info1	--下门芯
		,case when itmAv.info4 like N'%/%' then substring(itmAv.info4,charindex('/',itmAv.info4)+1,len(itmAv.info4)) end info2	--上门芯
		,itmAv.info3
		,(CASE when itmAv.info3 like N'%翻%' then N'横纹' else N'竖纹' END) AS info5
		,itmAv.info1 AS info6
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode in(N'OSDOOR',N'OSDOOR_BL') 
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
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
		WHERE  t.itmID=orie.itmID 
			AND t.itmIDInstance=orie.itmIDInstance
			AND t.olnID=orie.olnID 
			AND t.olnIDInstance=orie.olnIDInstance  
			AND orie.surCode<>N'No Edge Application'  
			AND atb.atbCode=N'Edge_Thickness_Code' 
			AND atbc.atbcCode=N'Item Info'
	) iatb
	LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge (NOLOCK) ON cEdge.edge1=iatb.Edge1
		AND cEdge.edge2=iatb.Edge2
		AND cEdge.edge3=iatb.Edge3
		AND cEdge.edge4=iatb.Edge4
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	/*获取品项的自定义属性*/
	outer apply(
		select
			max(case when iav.atbID=44 then iav.itmavValue end) info1   --备注
			,max(case when iav.atbID=45 then iav.itmavValue end) info3  --开门方向
			,max(case when iav.atbID=115 and iav.itmavValue not in ('STANDARD','-') then iav.itmavValue end) info4 --门芯
		from dbo.ItemAttributeValues iav
		where iav.itmID=t.itmID
			and iav.atbID in (45,44,115)    ---44 ItemInfo2 ,45 ItemInfo3,115 Info1
	)itmAv
	WHERE t.dlCode=N'MA'
	ORDER BY itmItemF.itmfCode,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		--,org.itmIDParent
		--,org.itmIDParentInstance
		,CAST(org.oriReqQty AS FLOAT) AS oriReqQty
		,org.itmIDSA
		,org.itmDescriptionSA
		,org.itmItemNumber
		,org.itmfCode
		--,org.itmfCode AS oItmfCode
		,org.itmDescription
		,org.itmDescription AS oItmDescription
		,org.itmfDescription
		,org.itmfDescription AS oItmfDescription
		,org.TopSurCode AS topSurCode
		,org.TopSurCode AS oTopSurCode
		,org.corCode
		,org.corCode AS oCorCode
		,CAST(org.dimCX AS FLOAT) AS dimCX
		,CAST(org.dimCX AS FLOAT) AS oDimCX
		,CAST(org.dimCY AS FLOAT) AS dimCY
		,CAST(org.dimCY AS FLOAT) AS oDimCY
		,CAST(org.dimCZ AS FLOAT) AS dimCZ
		,CAST(org.dimCZ AS FLOAT) AS oDimCZ
		,CAST(org.dimFX AS FLOAT) AS dimFX
		,CAST(org.dimFX AS FLOAT) AS oDimFX
		,CAST(org.dimFY AS FLOAT) AS dimFY
		,CAST(org.dimFY AS FLOAT) AS oDimFY
		,CAST(org.dimFZ AS FLOAT) AS dimFZ
		,CAST(org.dimFZ AS FLOAT) AS oDimFZ
		,CAST(org.dimCX*org.dimCY/100000 AS DECIMAL(18,2)) AS cArea
		,CAST(org.dimCX*org.dimCY/100000 AS DECIMAL(18,2)) AS oCArea
		,CAST(org.dimFX*org.dimFY/100000 AS DECIMAL(18,2)) AS Area
		,CAST(org.dimFX*org.dimFY/100000 AS DECIMAL(18,2)) AS oArea
		,ISNULL(org.edgeCode,N'0000') AS edgeCode
		,ISNULL(org.edgeCode,N'0000') AS oEdgeCode
		,org.actions
		,org.info1
		,org.info1 AS oInfo1
		,org.info2
		,org.info2 AS oInfo2
		,org.info3
		,org.info3 AS oInfo3
		,org.info5
		,org.info5 AS oInfo5
		,org.info6
		,org.info6 AS oInfo6
		,ha.hole	AS info7	
		,ha.holedis	AS info8
		,ha.newdm1	AS info9
		,ha.newdm2	AS info10
		,ha.newdm3	AS info11
		,ha.newdm4	AS info12
		,ha.newdm5	AS info13
		,ha.newdmRemark AS info14
		,ha.holeRemark AS info15
		,ha.Remark AS oInfo6
		,ha.hole AS oInfo7
		,ha.holedis AS oInfo8
		,ha.newdm1 AS oInfo9
		,ha.newdm2 AS oInfo10
		,ha.newdm3 AS oInfo11
		,ha.newdm4 AS oInfo12
		,ha.newdm5 AS oInfo13
		,ha.newdmRemark AS oInfo14
		,ha.holeRemark AS oInfo15
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price		--单价
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(org.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=org.ordId AND ha.itmID = org.itmID
	WHERE org.ordId=@ordID
		AND org.pageName=@pageName
END
