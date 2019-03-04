using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using DevExpress.Data;
using DevExpress.Utils;
using DevExpress.XtraEditors.Repository;
using DevExpress.XtraGrid.Columns;
using DevExpress.XtraGrid.Views.Base;
using DevExpress.XtraGrid.Views.Grid;
using Tech2020.InSight.Oppein.Workers.Data;

namespace Tech2020.InSight.Oppein.Workers
{
    public partial class ManualOrdersForm : Form
    {
        private SqlConnection sqlCon;
        public ManualOrdersForm()
        {
            InitializeComponent();
        }

        public ManualOrdersForm(int algId)
        {
            InitializeComponent();
            SqlConnection sqlCon = new SqlConnection("Data Source=LP-Kevin;Initial Catalog=inSight_OPP;User ID=sa;Password=2020;Connect Timeout=15;");
            sqlCon.Open();
            DataTable table = ManualOrdersData.getManualOrdersNormal_GS(sqlCon, 123);
            if (table != null && table.Rows.Count > 0)
            {
                var cmName = String.Empty;
                var cmVisible=false;
                for (int i = 0; i < table.Columns.Count; i++)
                {
                    cmVisible = false;
                    cmName = table.Columns[i].ColumnName;
                    var dataType= getGridColumnType(table.Columns[i].DataType.Name);
                    if (cmName.IndexOf("_raw") ==-1)
                    {
                        cmVisible = true;
                    }
                    //this.gridPTGS.Columns.Add(new GridColumn() { Name = cmName, FieldName = cmName, Caption = cmName, VisibleIndex = i, UnboundType = dataType, Visible = cmVisible,Tag = cmName });
                    DevExpress.XtraGrid.Columns.GridColumn cl = new DevExpress.XtraGrid.Columns.GridColumn();
                    cl.Name = cmName;
                    cl.Caption = cmName;
                    cl.FieldName = cmName;
                    cl.OptionsColumn.AllowSize = true;
                    //cl.OptionsColumn.ReadOnly = true;
                    cl.OptionsColumn.AllowEdit = true;
                    cl.OptionsColumn.AllowMove = false;
                    cl.OptionsColumn.AllowSort = DevExpress.Utils.DefaultBoolean.False;
                    cl.OptionsColumn.AllowGroup = DevExpress.Utils.DefaultBoolean.False;
                    cl.OptionsFilter.AllowFilter = false;
                    cl.OptionsFilter.AllowAutoFilter = false;
                    if (cmName == "TopSurCode")
                    {
                        //下拉框
                        RepositoryItemComboBox ricbo= new RepositoryItemComboBox();
                        ricbo.AutoComplete = true;//自动搜索筛选       
                        ricbo.ImmediatePopup = true;
                        ricbo.DropDownRows = 5;
                        ricbo.Items.Add("asd黄色");
                        ricbo.Items.Add("dfasd黄色");
                        ricbo.Items.Add("米黄色");
                        ricbo.Items.Add("米黄色02");
                        ricbo.Items.Add("米黄色033");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("米黄色035");
                        ricbo.Items.Add("米黄色036");
                        ricbo.Items.Add("米黄色073");
                        ricbo.Items.Add("米黄色0fg3");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("米黄色045");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("111米黄色034");
                        ricbo.Items.Add("111米黄色035");
                        ricbo.Items.Add("111米黄色036");
                        ricbo.Items.Add("111米黄色073");
                        ricbo.Items.Add("11米黄色0fg3");
                        ricbo.Items.Add("11米黄色034");
                        ricbo.Items.Add("11米黄色045");
                        ricbo.Items.Add("11米黄色05");
                        cl.ColumnEdit = ricbo;
                        //comboBoxEdit1.Properties.AutoComplete = true;//自动搜索筛选
                    }
                    if (cmName == "itmfCode")
                    {
                        //下拉框
                        RepositoryItemMRUEdit ricbo = new RepositoryItemMRUEdit();
                        //ricbo.AutoComplete = true;//自动搜索筛选 
                        ricbo.ImmediatePopup = true;
                        //MruEdit是否允许编辑
                        ricbo.TextEditStyle = DevExpress.XtraEditors.Controls.TextEditStyles.DisableTextEditor;
                        //是否具有删除 绑定的数据源功能
                        ricbo.AllowRemoveMRUItems = false;
                        //ricbo.ImmediatePopup = true;
                        ricbo.DropDownRows = 5;
                        ricbo.Items.Add("侧板");
                        ricbo.Items.Add("dfasd黄色");
                        ricbo.Items.Add("米黄色");
                        ricbo.Items.Add("米黄色02");
                        ricbo.Items.Add("米黄色033");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("米黄色035");
                        ricbo.Items.Add("米黄色036");
                        ricbo.Items.Add("米黄色073");
                        ricbo.Items.Add("米黄色0fg3");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("米黄色045");
                        ricbo.Items.Add("米黄色034");
                        ricbo.Items.Add("111米黄色034");
                        ricbo.Items.Add("111米黄色035");
                        ricbo.Items.Add("111米黄色036");
                        ricbo.Items.Add("111米黄色073");
                        ricbo.Items.Add("11米黄色0fg3");
                        ricbo.Items.Add("11米黄色034");
                        ricbo.Items.Add("11米黄色045");
                        ricbo.Items.Add("11米黄色05");
                        cl.ColumnEdit = ricbo;
                        //comboBoxEdit1.Properties.AutoComplete = true;//自动搜索筛选
                    }
                    cl.Visible = cmVisible;
                    gridPTGS.Columns.Add(cl);
                }
                this.gridControlPTGS.DataSource = table;
            }
        }

        private void gridPTGS_CustomDrawCell(object sender, RowCellCustomDrawEventArgs e)
        {
            if (e.Column.VisibleIndex>1 && e.Column.FieldName.IndexOf("_raw") == -1 && e.RowHandle >= 0)
            {
                GridView grid = sender as GridView;
                var rawValue = grid.GetRowCellValue(e.RowHandle, e.Column.FieldName + "_raw");
                if (rawValue != null && !String.IsNullOrEmpty(rawValue.ToString()) && !String.IsNullOrEmpty(e.CellValue.ToString()))
                {
                    if (e.CellValue.ToString() != rawValue.ToString())
                    {
                        e.Appearance.BackColor = Color.Yellow;
                    }
                }
            }
        }
        private void gridPTGS_MouseMove(object sender, MouseEventArgs e)
        {
            // 获取鼠标焦点
            DevExpress.XtraGrid.Views.Grid.ViewInfo.GridHitInfo hi = this.gridPTGS.CalcHitInfo(new Point(e.X, e.Y));
            // 如果鼠标不是在行上.或者不在列上
            if (hi.RowHandle < 0 || hi.Column == null)
            {
                return;
            }
            // rowHandle为全局变量,如果上次指向的是这一行的数据.则这次不重新初始化ToolTip.(因为鼠标一移到列上面则会触发多次的MouseMove)
            // 如果RowHandle为不等于rowHandle则重新显示ToolTip
            // 获取行
            if (!string.IsNullOrEmpty(hi.Column.FieldName) && hi.Column.FieldName.IndexOf("_raw") == -1)
            {
               var s= hi.Column.Tag;
                GridView grid = sender as GridView;
                var curCellValue = grid.GetRowCellValue(hi.RowHandle, hi.Column.FieldName);
                var rawValue = grid.GetRowCellValue(hi.RowHandle, hi.Column.FieldName + "_raw");
                if(curCellValue!=null && rawValue!=null && !string.IsNullOrEmpty(rawValue.ToString()) && curCellValue.ToString()!= rawValue.ToString())
                {
                    ToolTipControllerShowEventArgs args = CreateShowArgs(rawValue.ToString());
                    // 设置ToolTip标题
                    //args.Title = "原始数据";
                    // 显示ToolTip 这里不可以用控件的坐标.要用屏幕的坐标Control.MousePosition
                    toolTipController1.ShowHint(args, System.Windows.Forms.Control.MousePosition);
                }
                else
                {
                    toolTipController1.HideHint();
                }
            }
            else
            {
                toolTipController1.HideHint();
            }
        }

        /// <summary>
        /// 创建显示ToolTip事件实例
        /// </summary>
        /// <param name="tooltipText"></param>
        /// <returns></returns>
        private ToolTipControllerShowEventArgs CreateShowArgs(string tooltipText)
        {
            ToolTipControllerShowEventArgs args = toolTipController1.CreateShowArgs();
            args.ToolTip = tooltipText;
            return args;
        }

        public static UnboundColumnType getGridColumnType(string DataType)
        {
            switch (DataType)
            {
                case "Int32":
                    return UnboundColumnType.Integer;
                case "Boolean":
                    return UnboundColumnType.Boolean;
                case "Decimal":
                    return UnboundColumnType.Decimal;
                case "DateTime":
                    return UnboundColumnType.DateTime;
                case "String":
                    return UnboundColumnType.String;
                default:
                    return UnboundColumnType.Bound;
            }
        }

        private void MenuAdd_Click(object sender, EventArgs e)
        {

        }
        private void MenuDel_Click(object sender, EventArgs e)
        {

        }
        private void MenuUpdate_Click(object sender, EventArgs e)
        {

        }
        private void MenuRefresh_Click(object sender, EventArgs e)
        {

        }
    }
}
