alter PROC [dbo].[spApp_GetYLOrdersNormal_KQBJ_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'烤漆部件顶线'
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
			,ori.oriismfg
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
			,pdg.pdgCode
			,olnp.olnpdNetPrice
			,ftr.UT48_127
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
		JOIN product.ProductGroups pdg (NOLOCK) ON pdg.pdgID = pd.pdgID
		OUTER APPLY
		(
			SELECT 
				opt.optDescription AS UT48_127 
			FROM dbo.OrderLineOptions olno  (NOLOCK)
			JOIN product.Options opt (NOLOCK) on olno.optID  =opt.optID
			WHERE olno.olnID=oln.olnID AND olno.ftrID=1385
		)ftr
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	SELECT
		t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmIDParent
		,t.itmIDParentInstance
		,t.itmItemNumber
		,SA.itmID AS itmIDSA
		,SA.itmDescription AS itmDescriptionSA
		,t.itmDescription
		,ISNULL(org.itmDescription,t.itmDescription) AS oItmDescription
		,itmf.itmfCode
		,itmf.itmfDescription
		,ISNULL(org.itmfDescription,itmf.itmfDescription) AS oItmfDescription
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
		,org.actions
		,itmAv.info3
		,org.info3 AS oInfo3
		,ISNULL(ha.Remark,org.info6) AS info6
		,org.info6 AS oInfo6
		,org.info15 AS info16
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
		
		--,CAST(ISNULL(ha.LegacyPrice,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))) AS FLOAT) AS LegacyPrice
		--,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
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
	JOIN dbo.CustomSetting_Opp cs (NOLOCK)on cs.SCode = itmf.itmfCode and cs.SDesc=N'KQM' AND itmf.itmfCode IN (N'ZSBJ-KQ',N'DX-KQ')
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
			/*路轨*/
	outer apply      
	(      
		SELECT MAX(case when iav.atbID=44 then CASE 
				  WHEN iav.itmavValue='1' THEN N'三节路轨10"(海蒂斯)'   
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
			END END)info16
			,MAX(case when iav.atbID=44 then iav.itmavValue end) info6  --备注
			,MAX(case when iav.atbID=45 then iav.itmavValue end) info3  --开门方向
		FROM dbo.ItemAttributeValues iav (NOLOCK)       
		WHERE iav.itmID =t.itmID 
			 and iav.atbID in (45,44,115)    ---44 ItemInfo2 ,45 ItemInfo3,115 Info1
	)itmAv
	WHERE 1 = 1
		AND ((t.pdgCode ='DX' and t.olnpdNetPrice >0)OR t.pdgCode <>'DX')  --顶线的价格为0，被过滤掉,非顶线的产品分类不过滤     20141031
	ORDER BY itmf.itmfDescription,oDim.dimFX DESC,oDim.dimFY DESC ,oDim.dimFZ DESC,t.itmDescription
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
			,ori.oriismfg
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
			,pdg.pdgCode
			,olnp.olnpdNetPrice
			,ftr.UT48_127
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
		JOIN product.ProductGroups pdg (NOLOCK) ON pdg.pdgID = pd.pdgID
		OUTER APPLY
		(
			SELECT 
				opt.optDescription AS UT48_127 
			FROM dbo.OrderLineOptions olno  (NOLOCK)
			JOIN product.Options opt (NOLOCK) on olno.optID  =opt.optID
			WHERE olno.olnID=oln.olnID AND olno.ftrID=1385
		)ftr
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,itmfDescription,topSurCode,corCode
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
		,itmItemF.itmfCode
		,itmf.itmfDescription
		,oriMat.TopSurCode AS topSurCode
		,oriMat.corCode
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,itmAv.info3
		,ISNULL(t.UT48_127,itmAv.info6) AS info6
		,itmAv.info16 AS info15
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
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
	JOIN dbo.CustomSetting_Opp cs (NOLOCK)on cs.SCode = itmf.itmfCode and cs.SDesc=N'KQM' AND itmf.itmfCode IN (N'ZSBJ-KQ',N'DX-KQ')
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
		/*路轨*/
	outer apply      
	(      
		SELECT MAX(case when iav.atbID=44 then CASE 
				  WHEN iav.itmavValue='1' THEN N'三节路轨10"(海蒂斯)'   
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
			END END)info16
			,MAX(case when iav.atbID=44 then iav.itmavValue end) info6  --备注
			,MAX(case when iav.atbID=45 then iav.itmavValue end) info3  --开门方向
		FROM dbo.ItemAttributeValues iav (NOLOCK)       
		WHERE iav.itmID =t.itmID 
			 and iav.atbID in (45,44,115)    ---44 ItemInfo2 ,45 ItemInfo3,115 Info1
	)itmAv
	WHERE 1 = 1
		AND ((t.pdgCode ='DX' and t.olnpdNetPrice >0)OR t.pdgCode <>'DX')  --顶线的价格为0，被过滤掉,非顶线的产品分类不过滤     20141031
	ORDER BY itmf.itmfDescription,oDim.dimFX DESC,oDim.dimFY DESC ,oDim.dimFZ DESC,t.itmDescription

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
		,CAST(org.dimFX AS FLOAT) AS dimFX
		,CAST(org.dimFX AS FLOAT) AS oDimFX
		,CAST(org.dimFY AS FLOAT) AS dimFY
		,CAST(org.dimFY AS FLOAT) AS oDimFY
		,CAST(org.dimFZ AS FLOAT) AS dimFZ
		,CAST(org.dimFZ AS FLOAT) AS oDimFZ
		,org.actions
		,org.info3
		,org.info3 AS oInfo3
		,org.info6
		,org.info6 AS oInfo6
		,org.info15 AS info16
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
