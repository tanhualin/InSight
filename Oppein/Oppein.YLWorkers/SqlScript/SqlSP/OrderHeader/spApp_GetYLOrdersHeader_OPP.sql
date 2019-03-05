CREATE PROC [dbo].[spApp_GetYLOrdersHeader_OPP]
	@algId INT	
AS
SET NOCOUNT ON;

SELECT
     ord.ordID				--订单ID
     ,ord.ordOrderNo		--订单号
     ,ord.ordPONumber		--合同号
	 ,oOrdAv.ordSource		--订单来源
	 ,otp.otpCode			--订单类型Code
	 ,otp.otpDescription	--订单类型
     ,CONVERT(NVARCHAR(10),ord.ordOrderDate,120) AS ordOrderDate		--订单日期
	 ,oOrdAv.Factory
FROM dbo.Orders ord
JOIN ALG.Orders alg ON alg.ordID = ord.ordID
JOIN dbo.OrderTypes otp ON otp.otpID = ord.otpID
OUTER APPLY
(
	SELECT 
		MAX(CASE WHEN ordAv.atbID=162 THEN ordAv.ordavValue END) AS ordSource
		,MAX(CASE WHEN ordAv.atbID=287 THEN atbl.atblDescription END) AS Factory
	FROM dbo.OrderAttributeValues ordAv
	LEFT JOIN dbo.AttributeList atbl ON atbl.atbID = ordAv.atbID AND atbl.atblCode = ordAv.ordavValue
	WHERE ordAv.ordID=ord.ordID
		AND ordAv.atbID IN(162,287)		--162 订单来源属性，287 加工车间属性
)oOrdAv
WHERE alg.algID=@algId