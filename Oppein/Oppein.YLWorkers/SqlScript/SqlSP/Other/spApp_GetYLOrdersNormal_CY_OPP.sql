ALTER PROC [dbo].[spApp_GetYLOrdersNormal_CY_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'CY单'
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
		,ISNULL(ha.WenLu,CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info5 END) AS info5
		,ISNULL(ha.newdmRemark,CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info14 END) AS info14
		,ISNULL(ha.holeRemark,CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info15 END) AS info15
		,ha.Remark AS info6

		,ISNULL(org.info5,ha.WenLu)AS oInfo5
		,ISNULL(org.info14,ha.newdmRemark)AS oInfo14
		,ISNULL(org.info15,ha.holeRemark)AS oInfo15
		,ISNULL(org.info6,ha.Remark) AS oInfo6
		,org.actions
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			END) AS LegacyPrice		--总价
		,NULL AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	/*
	取"CY_柜身"的长、宽、厚信息
	*/
	OUTER APPLY
	(
		SELECT
			MAX(CASE WHEN ftr.ftrCode = 'UT50_2' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info5	--长
			,MAX(CASE WHEN ftr.ftrCode = 'UT50_3' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info14	--宽
			,MAX(CASE WHEN ftr.ftrCode = 'UT50_4' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info15	--厚
		FROM dbo.OrderLineOptions olno(NOLOCK)
		JOIN product.Features ftr(NOLOCK) ON ftr.ftrID = olno.ftrID
			AND ftr.ftrCode IN ('UT50_2','UT50_3','UT50_4')
		WHERE olno.olnID = t.olnID
	)op2020
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	WHERE NOT (t.itmpID = 2 AND t.oriIsPurchased = 0) 
		AND itmf.itmfCode IN(N'CY_柜身',N'CY_收口条',N'CY_趟门')
	ORDER BY itmf.itmfDescription
			,op2020.info5 DESC
			,op2020.info14 DESC
			,op2020.info15 DESC

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
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,itmfDescription
		,info5,info14,info15)
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
		,CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info5 END AS info5
		,(CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info14 END) AS info14
		,(CASE WHEN t.itmDescription NOT LIKE N'封边带%' THEN op2020.info15 END) AS info15
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode=N'OSCODE'
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode 
		/*
	取"CY_柜身"的长、宽、厚信息
	*/
	OUTER APPLY
	(
		SELECT
			MAX(CASE WHEN ftr.ftrCode = 'UT50_2' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info5	--长
			,MAX(CASE WHEN ftr.ftrCode = 'UT50_3' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info14	--宽
			,MAX(CASE WHEN ftr.ftrCode = 'UT50_4' THEN (CASE WHEN ISNUMERIC(olno.olnoValue)=1 THEN CAST(olno.olnoValue AS FLOAT) END) END) AS info15	--厚
		FROM dbo.OrderLineOptions olno(NOLOCK)
		JOIN product.Features ftr(NOLOCK) ON ftr.ftrID = olno.ftrID
			AND ftr.ftrCode IN ('UT50_2','UT50_3','UT50_4')
		WHERE olno.olnID = t.olnID
	)op2020
	WHERE NOT (t.itmpID = 2 AND t.oriIsPurchased = 0) 
		AND itmf.itmfCode IN(N'CY_柜身',N'CY_收口条',N'CY_趟门')
	ORDER BY itmf.itmfDescription
			,op2020.info5 DESC
			,op2020.info14 DESC
			,op2020.info15 DESC
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
		,org.info5
		,org.info5 AS oInfo5
		,org.info14
		,org.info14 AS oInfo14
		,org.info15
		,org.info15 AS oInfo15
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

