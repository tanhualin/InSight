CREATE TABLE [dbo].[CUS_YLOrdSliddingDoorItems_OPP]
(
	Idx INT IDENTITY(1,1)
	,itmID INT NOT NULL
	,itmDescription NVARCHAR(100) NOT NULL
	,itmItemNumber NVARCHAR(50) NOT NULL
	,pageName NVARCHAR(50) NOT NULL CHECK(pageName=N'趟门' OR pageName=N'铝框门')
	,corCode NVARCHAR(50)
	,Price DECIMAL(18,2)
	,Duty NVARCHAR(50)
	,itmfCode NVARCHAR(50)
	,itmfDescription NVARCHAR(100)
	,CONSTRAINT PK_CUS_YLOrdSliddingDoorItems_ItmID PRIMARY KEY NONCLUSTERED(itmID)
	,CONSTRAINT IX_CUS_YLOrdSliddingDoorItems_Idx UNIQUE CLUSTERED(Idx)
	,INDEX IX_CUS_YLOrdSliddingDoorItems_PageName NONCLUSTERED(pageName)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器趟门\铝框门虚拟品项' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdSliddingDoorItems_OPP'
GO