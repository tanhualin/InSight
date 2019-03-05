/*
功能描述：获取板件类别信息（遗留单）

修订记录：版本号    编辑时间      编辑人      修改描述
-------------------------------------------------------
            1.0.0   2014-10-15   谭华林      获取板件类别信息
                                                
InputParas:

*/

CREATE PROC [dbo].[spAPP_GetYLOrdCategory_OPP]
AS
SET NOCOUNT ON;
SELECT 
    pc.PlateCategory
FROM dbo.CUS_YLOrdPlateCategory_OPP pc
ORDER BY pc.SortOrder DESC
