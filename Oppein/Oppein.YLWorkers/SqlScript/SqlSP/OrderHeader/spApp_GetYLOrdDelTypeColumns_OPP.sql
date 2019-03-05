CREATE PROC [dbo].[spApp_GetYLOrdDelTypeColumns_OPP]
AS
SET NOCOUNT ON;
DECLARE @mOrdType dbo.YLOrdDelTableType_OPP
SELECT * FROM @mOrdType