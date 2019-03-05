USE [inSight]
GO
/****** Object:  StoredProcedure [dbo].[spApp_GetYLOrdSliddingDoorItems_OPP]    Script Date: 2019/2/28 16:25:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

	遗留单手工修改器 绑定虚拟部件

*/
ALTER PROC [dbo].[spApp_GetYLOrdSliddingDoorItems_OPP]
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
WHERE pageName=N'趟门'