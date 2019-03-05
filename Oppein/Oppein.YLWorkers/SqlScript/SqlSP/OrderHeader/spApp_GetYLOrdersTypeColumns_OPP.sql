
/*
	获取数据存储参数
*/
CREATE PROC [dbo].[spApp_GetYLOrdersTypeColumns_OPP]
AS
SET NOCOUNT ON;

DECLARE @mOrdType dbo.YLOrdTableType_OPP
SELECT * FROM @mOrdType
