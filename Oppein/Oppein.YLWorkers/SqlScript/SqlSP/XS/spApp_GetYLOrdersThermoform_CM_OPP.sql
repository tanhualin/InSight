
ALTER PROC [dbo].[spApp_GetYLOrdersThermoform_CM_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)=N'吸塑抽面'
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
			,oOlno.UT48_124
			,oOlno.UD34_22
			,oOlno.UT48_114
			--,oOlno.UT50_8
			--,oOlno.UT50_6
			,oOlno.UT50_30
			,oOlno.UT50_11
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		OUTER APPLY
		(
			SELECT 
				MAX(CASE WHEN olno.ftrID =1344 THEN olno.olnoValue END )AS UD34_22
				,MAX(CASE WHEN olno.ftrID =1367 THEN Opt.optDescription END )AS UT48_114
				--,MAX(CASE WHEN olno.ftrID =930  THEN opt.optDescription END )AS UT50_8
				--,MAX(CASE WHEN olno.ftrID =931  THEN opt.optDescription END )AS UT50_6	--材料
				,MAX(CASE WHEN olno.ftrID =942  THEN opt.optDescription END )AS UT50_30	--抽面工艺
				,MAX(CASE WHEN olno.ftrID =1386 THEN Opt.optDescription END )AS UT48_124	--纹路
				,MAX(CASE WHEN olno.ftrID =943 THEN (CASE WHEN opt.optID IN(4739,4435,4438,4560) THEN N'7mm拉手孔' END) END )AS UT50_11		--门板拉手备注
			FROM dbo.OrderLineOptions olno
			JOIN product.Options opt on opt.optID = olno.optID
			WHERE  olno.olnID = oln.olnID
				AND olno.ftrID in (1344,1367,942,1386,943)
		)oOlno
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
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(ISNULL(org.dimCX,oDim.dimCX) AS FLOAT) AS oDimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(ISNULL(org.dimCY,oDim.dimCY) AS FLOAT) AS oDimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(ISNULL(org.dimCZ,oDim.dimCZ) AS FLOAT) AS oDimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(ISNULL(org.dimFX,oDim.dimFX) AS FLOAT) AS oDimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(ISNULL(org.dimFY,oDim.dimFY) AS FLOAT) AS oDimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,CAST(ISNULL(org.dimFZ,oDim.dimFZ) AS FLOAT) AS oDimFZ
		,CAST(oDim.dimCX*oDim.dimCY/100000 AS DECIMAL(18,2)) AS cArea
		,(CASE WHEN org.dimCX IS NOT NULL THEN CAST(org.dimCX*org.dimCY/100000 AS DECIMAL(18,2))
			ELSE CAST(oDim.dimCX*oDim.dimCY/100000 AS DECIMAL(18,2)) END) AS oCArea
		,CAST(oDim.dimFX*oDim.dimFY/100000 AS DECIMAL(18,2)) AS Area
		,(CASE WHEN org.dimFX IS NOT NULL THEN CAST(org.dimFX*org.dimFY/100000 AS DECIMAL(18,2))
			ELSE CAST(oDim.dimFX*oDim.dimFY/100000 AS DECIMAL(18,2)) END) AS oArea
		,org.actions
		,t.UT50_30 AS info4		--工艺
		,ISNULL(ha.WenLu,t.UT48_124) AS info5
		,ISNULL(ha.Remark,t.UT50_11) AS info6
		,(CASE WHEN t.UT50_11 =N'NO PULL' THEN ha.newdmRemark ELSE ISNULL(ha.newdmRemark,t.UD34_22) END)AS info14	--拉手中心孔距
		,(CASE WHEN t.UT50_11 =N'NO PULL' THEN ha.holeRemark ELSE ISNULL(ha.holeRemark,t.UT48_114) END)AS info15	--拉手孔位置

		,ISNULL(org.info4,t.UT50_30) AS oInfo4		--工艺
		,COALESCE(org.info5,ha.WenLu,t.UT48_124) AS oInfo5
		,COALESCE(org.info6,ha.Remark,t.UT50_11) AS oInfo6
		,(CASE WHEN t.UT50_11 =N'NO PULL' THEN ISNULL(org.info14,ha.newdmRemark) ELSE COALESCE(org.info14,ha.newdmRemark,t.UD34_22) END)AS oInfo14	--拉手中心孔距
		,(CASE WHEN t.UT50_11 =N'NO PULL' THEN ISNULL(org.info15,ha.holeRemark) ELSE COALESCE(org.info15,ha.holeRemark,t.UT48_114) END)AS oInfo15	--拉手孔位置
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
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode =N'OSDRAWERFRONT'
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
	WHERE t.dlCode=N'MP'
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
			,oOlno.UT48_124
			,oOlno.UD34_22
			,oOlno.UT48_114
			--,oOlno.UT50_8
			--,oOlno.UT50_6
			,oOlno.UT50_30
			,oOlno.UT50_11
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		OUTER APPLY
		(
			SELECT 
				MAX(CASE WHEN olno.ftrID =1344 THEN olno.olnoValue END )AS UD34_22
				,MAX(CASE WHEN olno.ftrID =1367 THEN Opt.optDescription END )AS UT48_114
				--,MAX(CASE WHEN olno.ftrID =930  THEN opt.optDescription END )AS UT50_8
				--,MAX(CASE WHEN olno.ftrID =931  THEN opt.optDescription END )AS UT50_6	--材料
				,MAX(CASE WHEN olno.ftrID =942  THEN opt.optDescription END )AS UT50_30	--抽面工艺
				,MAX(CASE WHEN olno.ftrID =1386 THEN Opt.optDescription END )AS UT48_124	--纹路
				,MAX(CASE WHEN olno.ftrID =943 THEN (CASE WHEN opt.optID IN(4739,4435,4438,4560) THEN N'7mm拉手孔' END) END )AS UT50_11		--门板拉手备注
			FROM dbo.OrderLineOptions olno
			JOIN product.Options opt on opt.optID = olno.optID
			WHERE  olno.olnID = oln.olnID
				AND olno.ftrID in (1344,1367,942,1386,943)
		)oOlno
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,topSurCode,corCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info4,info5,info6,info14,info15)
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
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,t.UT50_30 AS info4		--工艺
		,t.UT48_124 AS info5
		,t.UT50_11 AS info6
		,(CASE WHEN t.UT50_11 != N'NO PULL' THEN t.UD34_22 END)AS info14	--拉手中心孔距
		,(CASE WHEN t.UT50_11 != N'NO PULL' THEN t.UT48_114 END)AS info15	--拉手孔位置
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID AND itmItemF.itmfCode =N'OSDRAWERFRONT'
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
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	WHERE t.dlCode=N'MP'
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
		,org.actions
		,org.info1
		,org.info1 AS oInfo1
		,org.info2
		,org.info2 AS oInfo2
		,org.info3
		,org.info3 AS oInfo3
		,org.info5
		,org.info5 AS oInfo5
		,NULL AS info6
		,NULL	AS info7	
		,NULL	AS info8
		,NULL	AS info9
		,NULL	AS info10
		,NULL	AS info11
		,NULL	AS info12
		,NULL	AS info13
		,NULL AS info14
		,NULL AS info15
		,NULL AS oInfo6
		,NULL AS oInfo7
		,NULL AS oInfo8
		,NULL AS oInfo9
		,NULL AS oInfo10
		,NULL AS oInfo11
		,NULL AS oInfo12
		,NULL AS oInfo13
		,NULL AS oInfo14
		,NULL AS oInfo15
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
