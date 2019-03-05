--DROP TABLE [dbo].[CUS_YLOrdGridColumnsData_OPP]

CREATE TABLE [dbo].[CUS_YLOrdGridColumnsData_OPP]
(
	Idx INT IDENTITY(1,1)
	,PageName NVARCHAR(50) NOT NULL
	,cmFieldName NVARCHAR(50) NOT NULL
	,cmFieldDesc NVARCHAR(50)
	,cmFieldType NVARCHAR(50) NOT NULL
	,cmFieldWidth INT
	,cmOriginalField NVARCHAR(50)
	,cmFieldEdit BIT NOT NULL
	,cmFieldVisible BIT NOT NULL
	,optType NVARCHAR(50) NOT NULL
	,optStoredProcedure NVARCHAR(100)
	,cmOrderSort INT NOT NULL
	,cmStates INT NOT NULL
	--,cmBindFeild NVARCHAR(50)
	,CONSTRAINT PK_YLOrdGridColumnsData_PageName_cmFieldName_cmStates PRIMARY KEY NONCLUSTERED(PageName,cmFieldName,cmStates)
	,CONSTRAINT FK_YLOrdGridColumnsData_PageName FOREIGN KEY(PageName) REFERENCES dbo.CUS_YLOrdPagesData_OPP(PageName)
	,CONSTRAINT IX_YLOrdGridColumnsData_Idx UNIQUE CLUSTERED(Idx)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器页签列字段表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdGridColumnsData_OPP'
GO