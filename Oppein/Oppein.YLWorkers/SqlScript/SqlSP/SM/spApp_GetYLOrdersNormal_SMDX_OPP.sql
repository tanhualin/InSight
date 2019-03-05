ALTER PROC [dbo].[spApp_GetYLOrdersNormal_SMDX_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'实木顶线'
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
			,pdg.pdgCode
			,olnp.olnpdNetPrice
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
		JOIN product.ProductGroups pdg (NOLOCK) ON pdg.pdgID = pd.pdgID 
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
		,org.info15 AS info16		--路轨(2020)
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
		--,CAST(ISNULL(ha.LegacyPrice,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))) AS FLOAT) AS LegacyPrice		--总价
		--,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON cs.SCode = itmf.itmfCode and cs.SDesc ='SMM' AND itmf.itmfCode IN ( N'DX-SM',N'XC-SM') 
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
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	LEFT JOIN dbo.MaterialSourceItems itmm(NOLOCK)
		on oriMat.TopSurCode = itmm.TopSurCode
		AND oriMat.corCode = itmm.corCode 
		AND oriMat.BotSurCode = itmm.BotSurCode
	LEFT JOIN dbo.Items itmMat (NOLOCK)on itmMat.itmID = itmm.itmID
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	WHERE ((t.pdgCode ='DX' and t.olnpdNetPrice >0)OR t.pdgCode <>'DX')  --顶线的价格为0，被过滤掉,非顶线的产品分类不过滤     20141031   
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
			,pdg.pdgCode
			,olnp.olnpdNetPrice
			,opt.optDescription AS UT48_127
			,ordAv.ordavValue
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderAttributeValues ordAv on ordAv.ordID=ord.ordID and ordAv.atbID=162
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
		JOIN product.ProductGroups pdg (NOLOCK) ON pdg.pdgID = pd.pdgID
		JOIN dbo.OrderLineOptions olno ON olno.olnID = oln.olnID AND olno.ftrID=1385
		JOIN product.Options opt on olno.optID  =opt.optID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,itmfDescription,topSurCode,corCode
		,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info6,info15)
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
		,ISNULL(t.UT48_127,itmAv.info6)	AS info6	--备注(2020)
		,ISNULL(itmpp_CAD.Railway,itmAv.info16) AS info16		--路轨(2020)
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON cs.SCode = itmf.itmfCode and cs.SDesc ='SMM' AND itmf.itmfCode IN ( N'DX-SM',N'XC-SM') 
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
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	LEFT JOIN dbo.MaterialSourceItems itmm(NOLOCK)
		on oriMat.TopSurCode = itmm.TopSurCode
		AND oriMat.corCode = itmm.corCode 
		AND oriMat.BotSurCode = itmm.BotSurCode
	LEFT JOIN dbo.Items itmMat (NOLOCK)on itmMat.itmID = itmm.itmID
	/*路轨*/
	outer apply      
	(      
		SELECT (CASE 
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
			END)info16
			,iav.itmavValue AS info6
		FROM dbo.ItemAttributeValues iav       
		WHERE 1=1 and iav.atbID =44 and iav.itmID =t.itmID    
	)itmAv
	OUTER APPLY(
		select top 1
			itm_pp.itmDescription2 Railway
		from dbo.OrderItems ori_pp
		join dbo.ItemItemFamilies itmif on itmif.itmID=ori_pp.itmID and itmif.itmfCode='Railway'
		join dbo.Items itm_pp on itm_pp.itmID=ori_pp.itmID
		where t.ordavValue='CAD'
			and ori_pp.itmIDParent=t.itmID
	) itmpp_CAD
	WHERE ((t.pdgCode ='DX' and t.olnpdNetPrice >0)OR t.pdgCode <>'DX')  --顶线的价格为0，被过滤掉,非顶线的产品分类不过滤     20141031   
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
		,org.info15 AS info16
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

