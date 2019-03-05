/*

	遗留单手工修改器 绑定加工车间
	取自定义属性:柜身车间（atbID=287、atbCode=Cabinet_Shop_Floor）
	的描述
*/

ALTER PROC spAPP_GetYLOrdFactory_OPP
	@keyValue NVARCHAR(50)
AS
SET NOCOUNT ON;

IF EXISTS(SELECT TOP 1 1 FROM [dbo].[CUS_YLOrdPageFactory_OPP] WHERE PageName=@keyValue)
BEGIN
	SELECT 
		Factory 
	FROM [dbo].[CUS_YLOrdPageFactory_OPP] 
	WHERE PageName=@keyValue
	ORDER BY orderSort
END
ELSE
BEGIN
	SELECT 
		Factory 
	FROM [dbo].[CUS_YLOrdFactory_OPP] 
	ORDER BY Factory DESC
END


--SELECT 
--	atbl.atblDescription 
--FROM dbo.AttributeList atbl 
--WHERE atbl.atbID=287
--	AND atbl.atblActive=1
--ORDER BY atbl.atblCode DESC
