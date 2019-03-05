ALTER PROC [dbo].[spApp_GetYLOrdersNormal_WJ_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)=N'普通五金'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

--DECLARE @ordID INT = 3914472
--	,@pageName NVARCHAR(50) = N'普通五金'
--	,@Factory NVARCHAR(50)

DECLARE @PlateCategory NVARCHAR(50)
SELECT @PlateCategory=PlateCategory FROM [dbo].[CUS_YLOrdPagesData_OPP] WHERE PageName=@pageName
SELECT @Factory=FactoryDefualt FROM [dbo].[CUS_YLOrdPageFactoryDefualt_OPP] WHERE Factory=@Factory AND PageName=@pageName 
--判断原始表数据是否存在(若存则关联，若不存在则插入)
IF EXISTS(SELECT 1 FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] WHERE ordId=@ordID AND pageName=@pageName)
BEGIN
	;WITH T AS
	(
		SELECT 
			org.itmID
			,MAX(org.itmDescription) AS itmDescription
			,MAX(org.info2) AS info2
			--,SUM(org.oriReqQty) AS oriReqQty
			,MAX(org.actions) AS actions
			,SUM(CASE WHEN org.info5 IS NOT NULL AND ISNUMERIC(org.info5)=1 THEN CAST(org.info5 AS FLOAT) ELSE 0 END)AS oriReqQty
			,CAST(org.dimCX AS FLOAT) AS dimCX
			,CAST(org.dimCY AS FLOAT) AS dimCY
			,CAST(org.dimCZ AS FLOAT) AS dimCZ
			--,CAST(org.dimFX AS FLOAT) AS dimFX
			--,CAST(org.dimFY AS FLOAT) AS dimFY
			--,CAST(org.dimFZ AS FLOAT) AS dimFZ
		FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
		WHERE org.ordId=@ordID
			AND org.pageName=@pageName
			AND org.info2 IS NULL	--排除取上级尺寸的品项
			--AND org.info2=N'0'	--排除取上级尺寸的品项
		GROUP BY org.itmID
			,org.dimCX
			,org.dimCY
			,org.dimCZ
			--,org.dimFX
			--,org.dimFY
			--,org.dimFZ
	),TT AS
	(
		SELECT 
			ori.itmID
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
			,itm.itmDescription2
			,itm.PrimaryUOMCode
			,itmf.itmfCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		JOIN dbo.ItemItemFamilies itmf (NOLOCK) ON itm.itmID=itmf.itmID
		WHERE ord.ordID = @ordID
	),TC AS
	(
		SELECT
			t.itmID
			,CAST(SUM(t.oriReqQty)AS FLOAT) AS oriReqQty
			,t.PrimaryUOMCode
			,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmItemNumber ELSE  HARDWARE.itmItemNumber END AS itmItemNumber
			,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmDescription2 ELSE  HARDWARE.itmDescription END AS itmDescription
			,t.itmfCode
			,CAST(NULLIF(HARDWARE.dimFX,0)AS FLOAT) as dimFX
			,CAST(NULLIF(HARDWARE.dimFY,0)AS FLOAT) as dimFY
			,CAST(NULLIF(HARDWARE.dimFZ,0)AS FLOAT) as dimFZ
			,cs.SCatagory
			,HARDWARE.info2
			,(CASE WHEN HARDWARE.info2 IS NOT NULL THEN HARDWARE.info2 ELSE t.itmID END) AS itmIDHa
		FROM TT t
		JOIN TT SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
		JOIN TT oriParent (NOLOCK)
			ON t.itmIDParent=oriParent.itmID  
			AND t.itmIDParentInstance=oriParent.itmIDInstance  
			AND t.olnID=oriParent.olnID  
			AND t.olnIDInstance=oriParent.olnIDInstance
		LEFT JOIN dbo.ItemDimensions dim (NOLOCK) ON dim.itmID=t.itmID and dim.dimID=1
		LEFT JOIN dbo.ItemDimensions dimParent (NOLOCK) ON dimParent.dimID=1 AND oriParent.itmID=dimParent.itmID 
		OUTER APPLY
		(
			SELECT  opt.optDescription
			FROM dbo.ItemPropertyValues ipval (NOLOCK)
			JOIN Product.Options opt (NOLOCK) ON ipvValue = opt.optCode
			WHERE ipval.itmID = t.itmID
			AND ipval.cpID in(5169,5170)
		) ipv
		LEFT JOIN dbo.ItemCosts itmc (NOLOCK) ON t.itmID=itmc.itmID AND itmc.icsID=2 
		CROSS APPLY
		(
			SELECT 
				CASE WHEN t.itmfCode = N'doorHardware' THEN N'门铰' ELSE t.itmItemNumber END  as itmItemNumber
				,CASE WHEN t.itmfCode = N'doorHardware' THEN ipv.optDescription  ELSE ISNULL(t.itmDescription2, t.itmDescription) END as itmDescription           
				,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimX ELSE ISNULL(dim.dimX,0) END as dimFX  
				,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimY ELSE ISNULL(dim.dimY,0) END as dimFY
				,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimZ ELSE ISNULL(dim.dimZ,0) END as dimFZ
				,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN oriParent.itmID END AS info2 
		) HARDWARE
		LEFT JOIN dbo.Items  itm_1 (NOLOCK) ON t.itmDescription=itm_1.itmItemNumber
		LEFT JOIN  dbo.ItemItemFamilies itmf1 (NOLOCK) ON itm_1.itmID=itmf1.itmID  
		OUTER APPLY(
				SELECT CASE WHEN t.itmItemNumber LIKE N'%加固条%' 
						OR t.itmItemNumber LIKE N'%衣通灯%' 
						OR t.itmItemNumber LIKE N'%层板灯%' 
						OR t.itmItemNumber LIKE N'%挂衣杆%' 
						OR t.itmItemNumber LIKE N'%铝包覆%' THEN itmf1.itmfCode ELSE t.itmfCode END AS itmfCode
			
		) itmfAll
		JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON CS.FurnitureKittingList ='WJ' and itmfAll.itmfCode=cs.SCode 
		WHERE NOT(t.oriIsPurchased = 0 AND t.itmpID = 2)
		GROUP BY t.itmID
			,t.itmItemNumber
			,t.itmDescription
			,t.itmDescription2
			,t.PrimaryUOMCode
			,itm_1.itmItemNumber
			,itm_1.itmDescription2
			,dim.dimX
			,dim.dimY
			,dim.dimZ
			,t.itmfCode
			,cs.SCatagory
			,HARDWARE.itmItemNumber
			,HARDWARE.itmDescription
			,HARDWARE.dimFX
			,HARDWARE.dimFY
			,HARDWARE.dimFZ
			,HARDWARE.info2
	)
	SELECT 
		tt.itmID
		,tt.itmID AS olnID
		,tt.itmItemNumber
		,tt.itmDescription
		,ISNULL(t.itmDescription,tt.itmDescription) AS oItmDescription
		,tt.oriReqQty AS oriReqQty
		,t.oriReqQty AS oOriReqQty
		,tt.PrimaryUOMCode
		,t.actions
		--,tt.itmfCode
		,tt.SCatagory AS itmfCode
		,tt.info2
		,tt.oriReqQty AS info5
		,tt.dimFX AS dimFX
		,t.dimCX AS oDimFX		----将尺寸数量保存到裁切尺寸，作为原始数据
		,tt.dimFY AS dimFY
		,t.dimCY  AS oDimFY
		,tt.dimFZ AS dimFZ
		,t.dimCZ AS oDimFZ
		,tt.dimFX AS dimCX	--保留上次更新值(判断当前尺寸是否修改)
		,tt.dimFY AS dimCY	--保留上次更新值(判断当前尺寸是否修改)
		,tt.dimFZ AS dimCZ	--保留上次更新值(判断当前尺寸是否修改)
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(ha.LegacyPrice AS FLOAT) AS LegacyPrice
	FROM TC tt
	LEFT JOIN T t ON t.itmID=tt.itmID
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = tt.itmIDHa AND ha.ordID=@ordID
	ORDER BY tt.SCatagory,tt.itmItemNumber
END
ELSE
BEGIN
	;WITH T AS
	(
		SELECT 
			ori.itmID
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
			,itm.itmDescription2
			,itm.PrimaryUOMCode
			,itmf.itmfCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		JOIN dbo.ItemItemFamilies itmf (NOLOCK) ON itm.itmID=itmf.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,dlCode,oriReqQty,primaryUOMCode
		,itmItemNumber,itmDescription,itmfCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,info1,info2,info3,info4,info5)
	SELECT
		@ordID AS ordID
		,@pageName AS pageName
		,t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmIDParent
		,t.itmIDParentInstance
		,SA.itmID AS itmIDSA
		,t.dlCode
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty
		,t.PrimaryUOMCode
		,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmItemNumber ELSE  HARDWARE.itmItemNumber END AS itmItemNumber
		,CASE WHEN t.itmItemNumber LIKE N'%加固条%' OR t.itmItemNumber LIKE N'%衣通灯%' OR t.itmItemNumber LIKE N'%层板灯%' OR t.itmItemNumber LIKE N'%挂衣杆%' OR t.itmItemNumber LIKE N'%铝包覆%'  THEN itm_1.itmDescription2 ELSE  HARDWARE.itmDescription END AS itmDescription
		,t.itmfCode
		,NULLIF(HARDWARE.dimFX,0) as dimCX
		,NULLIF(HARDWARE.dimFY,0) as dimCY
		,NULLIF(HARDWARE.dimFZ,0) as dimCZ
		,NULLIF(HARDWARE.dimFX,0) as dimFX
		,NULLIF(HARDWARE.dimFY,0) as dimFY
		,NULLIF(HARDWARE.dimFZ,0) as dimFZ
		,cs.SCatagory
		,HARDWARE.info2
		,oriParent.itmIDParent AS itmIDParent_P
		,oriParent.itmIDParentInstance AS itmIDParentInstance_P
		,CAST(t.oriReqQty AS FLOAT) AS info5
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN T oriParent (NOLOCK)
		ON t.itmIDParent=oriParent.itmID  
		AND t.itmIDParentInstance=oriParent.itmIDInstance  
		AND t.olnID=oriParent.olnID  
		AND t.olnIDInstance=oriParent.olnIDInstance
	LEFT JOIN dbo.ItemDimensions dim (NOLOCK) ON dim.itmID=t.itmID and dim.dimID=1
	LEFT JOIN dbo.ItemDimensions dimParent (NOLOCK) ON dimParent.dimID=1 AND oriParent.itmID=dimParent.itmID 
	OUTER APPLY
	(
		SELECT  opt.optDescription
		FROM dbo.ItemPropertyValues ipval (NOLOCK)
		JOIN Product.Options opt (NOLOCK) ON ipvValue = opt.optCode
		WHERE ipval.itmID = t.itmID
		AND ipval.cpID in(5169,5170)
	) ipv
	LEFT JOIN dbo.ItemCosts itmc (NOLOCK) ON t.itmID=itmc.itmID AND itmc.icsID=2 
	CROSS APPLY
	(
		SELECT 
			CASE WHEN t.itmfCode = N'doorHardware' THEN N'门铰' ELSE t.itmItemNumber END  as itmItemNumber
			,CASE WHEN t.itmfCode = N'doorHardware' THEN ipv.optDescription  ELSE ISNULL(t.itmDescription2, t.itmDescription) END as itmDescription           
			,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimX ELSE ISNULL(dim.dimX,0) END as dimFX  
			,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimY ELSE ISNULL(dim.dimY,0) END as dimFY
			,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN dimParent.dimZ ELSE ISNULL(dim.dimZ,0) END as dimFZ
			,CASE WHEN oriParent.itmfCode in (N'Hardware_SPP',N'PWRBXL',N'Hardware') THEN oriParent.itmID END AS info2 
	) HARDWARE
	LEFT JOIN dbo.Items  itm_1 (NOLOCK) ON t.itmDescription=itm_1.itmItemNumber
	LEFT JOIN  dbo.ItemItemFamilies itmf1 (NOLOCK) ON itm_1.itmID=itmf1.itmID  
	OUTER APPLY(
			SELECT CASE WHEN t.itmItemNumber LIKE N'%加固条%' 
					OR t.itmItemNumber LIKE N'%衣通灯%' 
					OR t.itmItemNumber LIKE N'%层板灯%' 
					OR t.itmItemNumber LIKE N'%挂衣杆%' 
					OR t.itmItemNumber LIKE N'%铝包覆%' THEN itmf1.itmfCode ELSE t.itmfCode END AS itmfCode
			
	) itmfAll
	JOIN dbo.CustomSetting_Opp cs (NOLOCK) ON CS.FurnitureKittingList ='WJ' and itmfAll.itmfCode=cs.SCode 
	WHERE NOT(t.oriIsPurchased = 0 AND t.itmpID = 2)
	ORDER BY t.olnID,t.olnIDInstance

	SELECT 
		tt.itmID
		,tt.itmID AS olnID	-- 替换时保存被替换的品项
		,tt.itmItemNumber
		,tt.itmDescription
		,tt.itmDescription AS oItmDescription
		,CAST(SUM(tt.oriReqQty)AS FLOAT) AS oriReqQty
		,CAST(SUM(tt.oriReqQty)AS FLOAT) AS oOriReqQty
		,tt.PrimaryUOMCode
		,MAX(tt.actions) AS actions
		--,tt.itmfCode
		,tt.info1 AS itmfCode
		,tt.info2
		,SUM(tt.oriReqQty) AS info5
		,CAST(tt.dimFX AS FLOAT) AS dimFX
		,CAST(tt.dimFX AS FLOAT) AS oDimFX
		,CAST(tt.dimFY AS FLOAT) AS dimFY
		,CAST(tt.dimFY AS FLOAT) AS oDimFY
		,CAST(tt.dimFZ AS FLOAT) AS dimFZ
		,CAST(tt.dimFZ AS FLOAT) AS oDimFZ
		,CAST(tt.dimFX AS FLOAT) AS dimCX	--保留上次更新值(判断当前尺寸是否修改)
		,CAST(tt.dimFY AS FLOAT) AS dimCY	--保留上次更新值(判断当前尺寸是否修改)
		,CAST(tt.dimFZ AS FLOAT) AS dimCZ	--保留上次更新值(判断当前尺寸是否修改)
		,@Factory AS Factory
		,ha.Duty AS Duty
		,@PlateCategory AS PlateCategory
		,ha.LegacyPrice AS LegacyPrice
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] tt
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=tt.ordId AND ha.itmID = tt.itmID
	WHERE tt.ordId=@ordID
		AND tt.pageName=@pageName
	GROUP BY tt.itmID
			,tt.itmItemNumber
			,tt.itmDescription
			,tt.PrimaryUOMCode
			--,tt.itmfCode
			,tt.info1
			,tt.info2
			,tt.dimFX
			,tt.dimFY
			,tt.dimFZ
			,ha.Duty
			,ha.LegacyPrice
	ORDER BY tt.info1,tt.itmItemNumber
END
