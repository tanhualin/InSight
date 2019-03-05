alter PROC [dbo].[spApp_GetYLOrdersNormal_TM_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'大理石台面'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;
--DECLARE @ordID INT=4476465

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
		,t.itmItemNumber
		,SA.itmID AS itmIDSA
		,SA.itmDescription AS itmDescriptionSA
		,itmItemF.itmfCode
		,t.itmDescription
		,ISNULL(org.itmDescription,t.itmDescription) AS oItmDescription
		,itmf.itmfDescription
		,ISNULL(org.itmfDescription,itmf.itmfDescription) AS oItmfDescription
		,OIM.TopSurCode AS topSurCode
		,ISNULL(org.topSurCode,OIM.TopSurCode) AS oTopSurCode
		,OIM.corCode
		,ISNULL(org.corCode,OIM.corCode) AS oCorCode
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(ISNULL(org.dimCX,oDim.dimCX) AS FLOAT) AS oDimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(ISNULL(org.dimCY,oDim.dimCY) AS FLOAT) AS oDimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(ISNULL(org.dimCZ,oDim.dimCZ) AS FLOAT) AS oDimCZ
		,CAST(CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3))AS FLOAT)AS cArea
		,(CASE WHEN org.dimCX IS NOT NULL THEN CAST(org.dimCX*org.dimCY/1000000 AS DECIMAL(18,3))
			ELSE CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3)) END) AS oCArea
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(ISNULL(org.dimFX,oDim.dimFX) AS FLOAT) AS oDimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(ISNULL(org.dimFY,oDim.dimFY) AS FLOAT) AS oDimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,CAST(ISNULL(org.dimFZ,oDim.dimFZ) AS FLOAT) AS oDimFZ
		,CAST(CAST(oDim.dimFX*oDim.dimFY/1000000 AS DECIMAL(18,3))AS FLOAT)AS Area
		,CAST((CASE WHEN org.dimFX IS NOT NULL THEN CAST(org.dimFX*org.dimFY/1000000 AS DECIMAL(18,3))
			ELSE CAST(oDim.dimFX*oDim.dimFY/1000000 AS DECIMAL(18,3)) END) AS FLOAT) AS oArea
		,ha.Remark	AS info6	--备注(2020)
		,COALESCE(org.info6,ha.Remark)	AS oInfo6	--备注(2020)
		,org.actions
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
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	JOIN dbo.CustomSetting_Opp cs on cs.SCode = itmf.itmfCode and cs.FurnitureKittingList ='XS_3'
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(19,2))  END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(19,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
		/*获取材料信息*/
	left Join dbo.OrderItemMaterials OIM ON oim.itmID=t.itmID
		and oim.itmIDInstance=t.itmIDInstance
		and oim.olnID=t.olnID
		AND oim.olnIDInstance=t.olnIDInstance
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	WHERE t.dlCode ='MP' 
		AND OIM.TopSurCode in (N'炫黑WTY315',N'黑水晶WTY131',N'海市蜃楼WTY140',N'白水晶PWTY1001')
	ORDER BY itmf.itmfDescription,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

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
			,ftrUT.UT48_127
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		outer apply
		(
			select opt.optDescription AS UT48_127
			from dbo.OrderLineOptions olno
			JOIN product.Options opt on olno.optID  =opt.optID
			WHERE  olno.olnID  =oln.olnID
				AND olno.ftrID = 1385
		)ftrUT
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,itmfDescription,topSurCode,corCode
		,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info6)
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
		,itmf.itmfDescription
		,OIM.TopSurCode AS topSurCode
		,OIM.corCode
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,t.UT48_127	AS info6	--备注(2020)
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode=N'OSCODE'
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode 
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(19,2))  END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(19,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
	/*获取材料信息*/
	left Join dbo.OrderItemMaterials OIM ON oim.itmID=t.itmID
		and oim.itmIDInstance=t.itmIDInstance
		and oim.olnID=t.olnID
		AND oim.olnIDInstance=t.olnIDInstance
	WHERE t.dlCode ='MP' 
		AND OIM.TopSurCode in (N'炫黑WTY315',N'黑水晶WTY131',N'海市蜃楼WTY140',N'白水晶PWTY1001')
	ORDER BY itmf.itmfDescription,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		--,org.itmIDParent
		--,org.itmIDParentInstance
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
		,CAST(CAST(org.dimCX*org.dimCY/1000000 AS DECIMAL(18,3))AS FLOAT)AS cArea
		,CAST(CAST(org.dimCX*org.dimCY/1000000 AS DECIMAL(18,3))AS FLOAT)AS oCArea
		,CAST(org.dimFX AS FLOAT) AS dimFX
		,CAST(org.dimFX AS FLOAT) AS oDimFX
		,CAST(org.dimFY AS FLOAT) AS dimFY
		,CAST(org.dimFY AS FLOAT) AS oDimFY
		,CAST(org.dimFZ AS FLOAT) AS dimFZ
		,CAST(org.dimFZ AS FLOAT) AS oDimFZ
		,CAST(CAST(org.dimFX*org.dimFY/1000000 AS DECIMAL(18,3))AS FLOAT)AS Area
		,CAST(CAST(org.dimFX*org.dimFY/1000000 AS DECIMAL(18,3))AS FLOAT)AS oArea
		,org.info6
		,org.info6 AS oInfo6
		,org.actions
		,@Factory AS Factory
		,ha.Duty AS Duty
		,@PlateCategory AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price		--单价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(org.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=org.ordId AND ha.itmID = org.itmID
	WHERE org.ordId=@ordID
		AND org.pageName=@pageName
END

