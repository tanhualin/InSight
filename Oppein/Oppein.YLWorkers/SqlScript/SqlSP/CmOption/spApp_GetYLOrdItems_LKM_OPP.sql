
/*

	遗留单手工修改器 绑定虚拟部件

*/
CREATE PROC [dbo].[spApp_GetYLOrdItems_LKM_OPP]
	@keyWordEx  NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

SELECT 
	itmID
	,itmItemNumber
	,itmDescription
	,corCode
	,Price
	,Duty
	,itmfCode
	,itmfDescription
FROM [dbo].[CUS_YLOrdSliddingDoorItems_OPP]
WHERE pageName=N'铝框门'