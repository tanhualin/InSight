alter PROC [dbo].[spApp_GetYLOrdersNormal_SMCM_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'实木抽面'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;
--DECLARE @ordID INT=4982114

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
		 t.olnID
		,t.olnIDInstance
		,t.itmID
		,t.itmIDInstance
		--,t.itmIDParent
		--,t.itmIDParentInstance
		,t.itmDescription		--工艺
		,SA.itmID AS itmIDSA
		,SA.itmDescription AS itmDescriptionSA
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty	--数量
		,itmItemF.itmfCode
		,itmf.itmfDescription
		,ISNULL(org.itmfDescription,itmf.itmfDescription) AS oItmfDescription
		,orim.topSurCode 
		,orim.corCode
		,itmAv.info3	--开门方向
		,ha.Remark AS info6
		,itmAv.info16			--路轨(2020)	
		,CAST(oDim.dimFX AS FLOAT)AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,CAST(oDim.dimFX*oDim.dimFY/1000000 AS DECIMAL(18,3)) AS Area
		,CAST(oDim.dimCX AS FLOAT)AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3)) AS cArea
		,ISNULL(org.itmDescription,t.itmDescription) AS oItmDescription
		,ISNULL(org.topSurCode,orim.TopSurCode) AS oTopSurCode
		,ISNULL(org.corCode,orim.corCode) AS oCorCode
		,CAST(ISNULL(org.dimFX,oDim.dimFX)AS FLOAT) AS oDimFX
		,CAST(ISNULL(org.dimFY,oDim.dimFY)AS FLOAT) AS oDimFY
		,CAST(ISNULL(org.dimFZ,oDim.dimFZ)AS FLOAT) AS oDimFZ
		,(CASE WHEN org.dimFX IS NOT NULL THEN CAST(org.dimFX*org.dimFY/1000000 AS DECIMAL(18,3))
			ELSE CAST(oDim.dimFX*oDim.dimFY/1000000 AS DECIMAL(18,3)) END) AS oArea
		,CAST(ISNULL(org.dimCX,oDim.dimCX)AS FLOAT) AS oDimCX
		,CAST(ISNULL(org.dimCY,oDim.dimCY)AS FLOAT) AS oDimCY
		,CAST(ISNULL(org.dimCZ,oDim.dimCZ)AS FLOAT) AS oDimCZ
		,(CASE WHEN org.dimCX IS NOT NULL THEN CAST(org.dimCX*org.dimCY/1000000 AS DECIMAL(18,3))
		ELSE CAST(oDim.dimCX*oDim.dimCY/1000000 AS DECIMAL(18,3)) END) AS oCArea
		,ISNULL(org.info3,itmAv.info3) AS oInfo3
		,ISNULL(org.info6,ha.Remark) AS oInfo6
		,org.actions
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		--,CAST(ISNULL(ha.LegacyPrice,lp.LegacyPrice) AS FLOAT) AS LegacyPrice
		--,CAST(lp.LegacyPrice AS FLOAT) AS oLegacyPrice
		--,CAST(dimF.dimX * dimF.dimY/1000000 * COALESCE(ha.LegacyPrice,lp.LegacyPrice,0) AS DECIMAL(18,0)) AS Price
		,CAST(lp.LegacyPrice AS FLOAT) AS Price
		,CAST(ISNULL(ha.LegacyPrice,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))) AS FLOAT) AS LegacyPrice
		,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	JOIN dbo.CustomSetting_Opp cs on cs.SCode = itmf.itmfCode 
		AND cs.SDesc=N'SMM'	--IN ( 'SMM','SMC','SMD','SMZ') 
		AND itmf.itmfCode=N'DRAWER-SM'	-- in ('DOOR-SM','DRAWER-SM',N'ZSMB-SM',N'CYJ-SM')--N'DX-SM',N'TM-SM',N'ZSCB-SM',N'ZSBJ-SM'
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(19,1))  END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(19,1)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(19,1)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(19,1)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(19,1)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(19,1)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
	LEFT JOIN dbo.OrderItemMaterials orim(NOLOCK) ON orim.itmID = t.itmID 
		AND orim.itmIDInstance = t.itmIDInstance 
		AND orim.olnID = t.olnID 
		AND orim.olnIDInstance = t.olnIDInstance
	/*路轨*/
	outer apply      
	(      
		SELECT MAX(CASE WHEN iav.atbID=44 THEN 
				(CASE WHEN iav.itmavValue='1' THEN N'三节路轨10"(海蒂斯)'   
				  WHEN iav.itmavValue='2' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='3' THEN N'三节路轨14"(海蒂斯)'      
				  WHEN iav.itmavValue='4' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='5' THEN N'半拉带阻尼260mm路轨'  
				  WHEN iav.itmavValue='6' THEN N'半拉带阻尼310mm路轨'  
				  WHEN iav.itmavValue='7' THEN N'半拉带阻尼360mm路轨'  
				  WHEN iav.itmavValue='8' THEN N'半拉带阻尼410mm路轨'    
				  WHEN iav.itmavValue='9' THEN N'半拉不带阻尼410mm路轨'  
				  WHEN iav.itmavValue='10' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='11' THEN N'魔顺全拉阻尼300mm路轨'  
				  WHEN iav.itmavValue='12' THEN N'魔顺全拉阻尼400mm路轨'  
				  WHEN iav.itmavValue='13' THEN N'全拉带阻尼250mm路轨'  
				  WHEN iav.itmavValue='14' THEN N'全拉带阻尼350mm路轨'  
				  WHEN iav.itmavValue='24' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='30' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='34' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='40' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='41' THEN N'全拉不带阻尼400mm路轨'
				  WHEN iav.itmavValue='51' THEN N'百隆反弹250mm路轨' 
				  WHEN iav.itmavValue='54' THEN N'百隆反弹410mm路轨'  
				  WHEN iav.itmavValue='61' THEN N'全拉不带阻尼400mm路轨'        
				  WHEN iav.itmavValue='71' THEN N'全拉不带阻尼400mm路轨'  
				  WHEN iav.itmavValue='81' THEN N'国产三节路轨'  
				  WHEN iav.itmavValue='82' THEN N'国产三节路轨'  
				  WHEN iav.itmavValue='83' THEN N'国产三节路轨'
				--ELSE iav.itmavValue
				END)
			END)info16
			,MAX(CASE WHEN iav.atbID=45 THEN iav.itmavValue END)AS info3
		FROM dbo.ItemAttributeValues iav       
		WHERE 1=1 
			and iav.itmID =t.itmID
			and iav.atbID IN(44,45)
	)itmAv
	LEFT JOIN dbo.hole_analysis ha(NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	--WHERE t.dlCode=N'MA'
	ORDER BY itmf.itmfCode,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC
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
			,opt.optDescription AS UT48_127	--装饰部件的备注
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineOptions olno ON olno.olnID = oln.olnID AND olno.ftrID=1385
		JOIN product.Options opt on olno.optID  =opt.optID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,topSurCode,corCode
			,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info3,info6,info15)
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
		,itmF.itmfCode
		,orim.TopSurCode AS topSurCode
		,orim.corCode
		,CAST(oDim.dimCX AS FLOAT)AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT)AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,itmAv.info3	--开门方向
		,t.UT48_127 AS info6
		,itmAv.info16			--路轨(2020)	
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	JOIN dbo.CustomSetting_Opp cs on cs.SCode = itmf.itmfCode 
		AND cs.SDesc=N'SMM'	--IN ( 'SMM','SMC','SMD','SMZ') 
		AND itmf.itmfCode=N'DRAWER-SM'	-- in ('DOOR-SM','DRAWER-SM',N'ZSMB-SM',N'CYJ-SM')--N'DX-SM',N'TM-SM',N'ZSCB-SM',N'ZSBJ-SM'
	LEFT JOIN dbo.OrderItemMaterials orim(NOLOCK) ON orim.itmID = t.itmID 
		AND orim.itmIDInstance = t.itmIDInstance 
		AND orim.olnID = t.olnID 
		AND orim.olnIDInstance = t.olnIDInstance
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(19,1))  END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(19,1)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(19,1)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(19,1)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(19,1)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(19,1)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
	/*路轨*/
	outer apply      
	(      
		SELECT MAX(CASE WHEN iav.atbID=44 THEN 
				(CASE WHEN iav.itmavValue='1' THEN N'三节路轨10"(海蒂斯)'   
				  WHEN iav.itmavValue='2' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='3' THEN N'三节路轨14"(海蒂斯)'      
				  WHEN iav.itmavValue='4' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='5' THEN N'半拉带阻尼260mm路轨'  
				  WHEN iav.itmavValue='6' THEN N'半拉带阻尼310mm路轨'  
				  WHEN iav.itmavValue='7' THEN N'半拉带阻尼360mm路轨'  
				  WHEN iav.itmavValue='8' THEN N'半拉带阻尼410mm路轨'    
				  WHEN iav.itmavValue='9' THEN N'半拉不带阻尼410mm路轨'  
				  WHEN iav.itmavValue='10' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='11' THEN N'魔顺全拉阻尼300mm路轨'  
				  WHEN iav.itmavValue='12' THEN N'魔顺全拉阻尼400mm路轨'  
				  WHEN iav.itmavValue='13' THEN N'全拉带阻尼250mm路轨'  
				  WHEN iav.itmavValue='14' THEN N'全拉带阻尼350mm路轨'  
				  WHEN iav.itmavValue='24' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='30' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='34' THEN N'三节路轨16"(海蒂斯)'  
				  WHEN iav.itmavValue='40' THEN N'全拉带阻尼400mm路轨'  
				  WHEN iav.itmavValue='41' THEN N'全拉不带阻尼400mm路轨'
				  WHEN iav.itmavValue='51' THEN N'百隆反弹250mm路轨' 
				  WHEN iav.itmavValue='54' THEN N'百隆反弹410mm路轨'  
				  WHEN iav.itmavValue='61' THEN N'全拉不带阻尼400mm路轨'        
				  WHEN iav.itmavValue='71' THEN N'全拉不带阻尼400mm路轨'  
				  WHEN iav.itmavValue='81' THEN N'国产三节路轨'  
				  WHEN iav.itmavValue='82' THEN N'国产三节路轨'  
				  WHEN iav.itmavValue='83' THEN N'国产三节路轨'
				--ELSE iav.itmavValue
				END)
			END)info16
			,MAX(CASE WHEN iav.atbID=45 THEN iav.itmavValue END)AS info3
		FROM dbo.ItemAttributeValues iav       
		WHERE 1=1 
			and iav.itmID =t.itmID
			and iav.atbID IN(44,45)
	)itmAv
	--LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=@ordID AND ha.itmID = t.itmID
	--WHERE t.dlCode=N'MA'
	ORDER BY itmf.itmfCode,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		,org.itmIDSA
		,org.itmDescriptionSA
		,org.itmItemNumber
		,org.itmfCode
		,org.itmDescription
		,org.itmDescription AS oItmDescription
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
		,org.info3
		,org.info3 AS oInfo3
		,org.info6
		,org.info6 AS oInfo6
		,org.info15 AS info16
		--,ISNULL(org.edgeCode,N'0000') AS edgeCode
		--,ISNULL(org.edgeCode,N'0000') AS oEdgeCode
		,org.actions
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


