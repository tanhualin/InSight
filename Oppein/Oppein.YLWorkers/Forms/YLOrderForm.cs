using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using DevExpress.Utils;
using DevExpress.XtraEditors;
using DevExpress.XtraEditors.Controls;
using DevExpress.XtraEditors.Mask;
using DevExpress.XtraEditors.Repository;
using DevExpress.XtraGrid;
using DevExpress.XtraGrid.Columns;
using DevExpress.XtraGrid.Views.Base;
using DevExpress.XtraGrid.Views.Grid;
using DevExpress.XtraGrid.Views.Grid.ViewInfo;
using DevExpress.XtraTab;
using Tech2020.InSight.Oppein.YLWorkers.Models;

namespace Tech2020.InSight.Oppein.YLWorkers.Forms
{
    public partial class YLOrderForm : Form
    {
        #region 属性
        private int ordId { get; set; }
        private string ordSource { get; set; }
        private string Factory { get; set; }
        private SqlConnection SqlConn { get; set; }
        /// <summary>
        /// 保存数据
        /// </summary>
        private DataTable saveTable { get; set; }
        /// <summary>
        /// 页面汇总数据
        /// </summary>
        private List<YLOrdPagesTotalModel> pageTotal { get; set; }
        #endregion

        #region 初始化
        public YLOrderForm()
        {
            InitializeComponent();
        }
        public YLOrderForm(SqlConnection conn, int algId)
        {
            InitializeComponent();

            this.SqlConn = conn;
            var mOrdEntity = Data.YLOrdersData.getOrdersHeaderData(SqlConn, algId);
            if (mOrdEntity != null)
            {
                this.ordId = mOrdEntity.ordID;
                this.ordSource = mOrdEntity.ordSource;
                this.Factory = mOrdEntity.Factory;

                this.lblOrdNo.Text = mOrdEntity.ordOrderNo.ToString();
                this.lblPONumber.Text = mOrdEntity.ordPONumber;
                this.lblOtp.Text = mOrdEntity.otpDescription;
                this.lblOrdDate.Text = mOrdEntity.ordOrderDate;
                //初始化处理Table
                saveTable = Data.YLOrdersData.getTypeColumns(SqlConn);
                var gridColumns = Data.YLOrdersData.getGridColumnsData(SqlConn, mOrdEntity.ordID, mOrdEntity.ordSource);
                var gridPages = gridColumns.GroupBy(p => new { p.pageName, p.PageStoredProcedure, p.showPageColor })
                    .Select(p => new GridPagesModel() { pageName = p.Key.pageName, pageStored = p.Key.PageStoredProcedure, pageColor = p.Key.showPageColor }).ToList();
                if (gridPages.Count > 0)
                {
                    //绑定第一个页签及数据
                    PageOrder.Text = gridPages[0].pageName;
                    if (gridPages[0].pageColor)
                    {
                        PageOrder.Appearance.Header.BackColor = Color.Yellow;
                    }
                    else
                    {
                        PageOrder.Appearance.Header.BackColor = Color.Green;
                    }
                    GridOrder.Tag = gridPages[0].pageStored;
                    GridOrder.Name = gridPages[0].pageName;
                    #region View 属性事件设置
                    ViewOrder.Appearance.HeaderPanel.TextOptions.HAlignment = HorzAlignment.Center;
                    ViewOrder.OptionsView.ShowGroupPanel = false;
                    ViewOrder.OptionsSelection.MultiSelect = true;
                    ViewOrder.OptionsSelection.CheckBoxSelectorColumnWidth = 40;
                    ViewOrder.OptionsSelection.MultiSelectMode = GridMultiSelectMode.CheckBoxRowSelect;
                    ViewOrder.IndicatorWidth = 50;
                    ViewOrder.CustomDrawRowIndicator += new RowIndicatorCustomDrawEventHandler(grid_CustomDrawRowIndicator);
                    ViewOrder.MouseMove += new MouseEventHandler(grid_MouseMove);
                    ViewOrder.CustomDrawCell += new RowCellCustomDrawEventHandler(grid_CustomDrawCell);
                    ViewOrder.CellValueChanged += new CellValueChangedEventHandler(grid_CellValueChanged);
                    ViewOrder.CustomRowCellEdit += new CustomRowCellEditEventHandler(gridOrder_CustomRowCellEdit);
                    ViewOrder.ValidateRow += new ValidateRowEventHandler(grid_ValidateRow);
                    ViewOrder.Tag = gridPages[0].pageName;
                    //绑定第一个页签列
                    BindGridColumns(this.ViewOrder, gridColumns, gridPages[0].pageName);
                    //绑定页签
                    BindTabPages(gridPages, gridColumns);
                    DataTable table = Data.YLOrdersData.getStoredData(SqlConn, gridPages[0].pageStored, this.ordId, gridPages[0].pageName, this.Factory);
                    //绑定数据
                    GridOrder.DataSource = table;
                    if (table != null && table.Rows.Count == 0)
                    {
                        if (PageOrder.Appearance.Header.BackColor == Color.Yellow)
                        {
                            PageOrder.Appearance.Header.BackColor = Color.SandyBrown;
                        }
                        else
                        {
                            PageOrder.Appearance.Header.BackColor = Color.BurlyWood;
                        }
                    }
                    //
                    this.TabOrder.SelectedPageChanged += new TabPageChangedEventHandler(tabControl_SelectedPageChanged);
                    #endregion

                    //绑定汇总信息
                    pageTotal = Data.YLOrdersData.getYLOrdPagesTotalData(SqlConn, ordId).ToList();
                    if (table != null && table.Rows.Count > 0 && table.Columns.Contains("PlateCategory") && table.Columns.Contains("LegacyPrice"))
                    {
                        var totalModel = new YLOrdPagesTotalModel();
                        totalModel.PageName = GridOrder.Name;
                        totalModel.PlateCategory = table.Rows[0]["PlateCategory"].ToString();
                        if (!pageTotal.Contains(totalModel))
                        {
                            var value = table.Compute("SUM(LegacyPrice)", "LegacyPrice > 0");
                            if (value != null && value != DBNull.Value)
                            {
                                totalModel.TotalPrice = Convert.ToDecimal(value);
                                pageTotal.Add(totalModel);
                                //获取当前汇总
                                var curModel = new YLOrdPagesTotalModel();
                                curModel.PageName = totalModel.PageName;
                                curModel.PlateCategory = "汇总";
                                curModel.TotalPrice = Convert.ToDecimal(value);
                                if (pageTotal.Contains(curModel))
                                {
                                    pageTotal.Remove(curModel);
                                }
                                pageTotal.Add(curModel);
                                //获取整单汇总 板件类别的信息
                                var zpModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == totalModel.PlateCategory);
                                zpModel.TotalPrice = Convert.ToDecimal(value);

                                //获取整单汇总 汇总的信息
                                var zhModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == "汇总");
                                zhModel.TotalPrice = Convert.ToDecimal(value);
                            }
                        }
                    }
                    var curTotal = from p in pageTotal where p.PageName == "整单汇总" select p;
                    foreach (var cur in curTotal)
                    {
                        #region 当前汇总
                        LabelControl lbl = new LabelControl();
                        lbl.Appearance.Font = new Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
                        lbl.Text = cur.PlateCategory + ":";
                        lbl.Size = new Size(78, 21);
                        TextEdit tBox = new TextEdit();
                        tBox.Size = new Size(68, 21);
                        tBox.Tag = cur.PlateCategory;
                        tBox.Properties.Mask.MaskType = MaskType.Numeric;
                        //tBox.Properties.Mask.UseMaskAsDisplayFormat = true;
                        //tBox.Properties.Mask.EditMask = "[0-9].[0-9]*";
                        tBox.Text = "0";
                        var curPage = pageTotal.Find(p => p.PageName == gridPages[0].pageName && p.PlateCategory == cur.PlateCategory);
                        if (curPage != null && curPage.TotalPrice > 0)
                        {
                            tBox.Text = curPage.TotalPrice.ToString("0.##");
                        }
                        //tBox.EditValueChanging += new ChangingEventHandler(tBox_EditValueChanging);
                        //tBox.TextChanged += new EventHandler(tBox_TextChanged);
                        tBox.Validating += new CancelEventHandler(curBox_Validating);
                        curPanel.Controls.Add(lbl);
                        curPanel.Controls.Add(tBox);
                        #endregion

                        #region 整单汇总
                        LabelControl totalLbl = new LabelControl();
                        totalLbl.Appearance.Font = new Font("Tahoma", 10F, System.Drawing.FontStyle.Bold);
                        totalLbl.Text = cur.PlateCategory + ":";
                        totalLbl.Size = new Size(78, 21);
                        TextEdit totalBox = new TextEdit();
                        totalBox.Size = new Size(68, 21);
                        totalBox.Tag = cur.PlateCategory;
                        totalBox.Properties.Mask.MaskType = MaskType.Numeric;

                        totalBox.Text = cur.TotalPrice.ToString("0.##");
                        if (cur.PlateCategory != "汇总")
                        {
                            totalBox.Validating += new CancelEventHandler(totalBox_Validating);
                        }
                        totalPanel.Controls.Add(totalLbl);
                        totalPanel.Controls.Add(totalBox);
                        #endregion
                    }
                    //后台加载其他页签数据
                    Thread bindThread = new Thread(new ThreadStart(BindThreadData));
                    bindThread.Start();
                }
            }
        }
        #endregion

        #region 自定义该方法
        /// <summary>
        /// 绑定页签GridView列
        /// </summary>
        /// <param name="grid"></param>
        /// <param name="gridColumns"></param>
        /// <param name="pageName"></param>
        private void BindGridColumns(GridView grid, IList<GridColumnModel> gridColumns, string pageName)
        {
            var pGridColumns = from p in gridColumns where p.pageName == pageName select p;
            foreach (var entity in pGridColumns)
            {
                #region 绑定列
                GridColumn cm = new GridColumn();
                cm.Name = entity.cmFieldName;
                cm.Caption = entity.cmFieldDesc;
                cm.FieldName = entity.cmFieldName;
                //cm.VisibleIndex = entity.cmOrderSort;
                cm.Tag = entity.cmOriginalField;
                cm.UnboundType = Common.CommonHelper.getGridColumnType(entity.cmFieldType);
                cm.OptionsColumn.AllowEdit = entity.cmFieldEdit;
                cm.Visible = entity.cmFieldVisible;
                cm.OptionsColumn.AllowSize = true;
                cm.OptionsColumn.AllowSort = DefaultBoolean.True;
                cm.OptionsColumn.AllowGroup = DefaultBoolean.False;
                if (entity.cmFieldType.ToLower() == "int")
                {
                    cm.AppearanceCell.Options.UseTextOptions = true;
                    cm.AppearanceCell.TextOptions.HAlignment = HorzAlignment.Center;
                }
                if (entity.cmFieldWidth > 0)
                {
                    cm.MinWidth = entity.cmFieldWidth;
                }
                if (entity.optType.ToLower() == "textex")
                {
                    RepositoryItemTextEdit textBox = new RepositoryItemTextEdit();
                    textBox.Validating += new CancelEventHandler(tBox_Validating);
                    cm.ColumnEdit = textBox;
                }
                if (entity.optType.ToLower() == "comboboxex" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    RepositoryItemComboBox combox = new RecentlyUsedItemsComboBox();
                    combox.Tag = entity.optStoredProcedure;
                    combox.ImmediatePopup = false;
                    combox.AutoComplete = false;//自动搜索筛选
                    combox.TextEditStyle = TextEditStyles.Standard;
                    combox.AllowDropDownWhenReadOnly = DefaultBoolean.True;
                    combox.EditValueChanging += new ChangingEventHandler(combox_EditValueChanging);
                    combox.Validating += new CancelEventHandler(combox_Validating);

                    DataTable table = Data.YLOrdersData.getComboBoxData(SqlConn, entity.optStoredProcedure);
                    foreach (DataRow row in table.Rows)
                    {
                        combox.Items.Add(row[0].ToString());
                    }
                    cm.ColumnEdit = combox;
                }
                else if (entity.optType.ToLower() == "combobox" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    #region 绑定ComboBox
                    DataTable tb = Data.YLOrdersData.getStoredProcedureData(SqlConn, entity.optStoredProcedure);
                    if (tb != null && tb.Rows.Count > 0)
                    {
                        RepositoryItemMRUEdit ricbo = new RepositoryItemMRUEdit();
                        ricbo.AutoComplete = true;
                        ricbo.ImmediatePopup = true;
                        //MruEdit是否允许编辑
                        ricbo.TextEditStyle = TextEditStyles.DisableTextEditor;
                        //是否具有删除 绑定的数据源功能
                        ricbo.AllowRemoveMRUItems = false;
                        //ricbo.DropDownRows = 20;
                        //ricbo.Items.Clear();
                        foreach (DataRow row in tb.Rows)
                        {
                            ricbo.Items.Add(row[0].ToString());
                        }
                        ricbo.SelectedValueChanged += new EventHandler(ricbo_SelectedValueChanged);
                        cm.ColumnEdit = ricbo;
                    }
                    #endregion
                }
                else if (entity.optType.ToLower() == "comboboxkey" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    #region 绑定ComboBox
                    DataTable tb = Data.YLOrdersData.getComboBoxByPageName(SqlConn, entity.optStoredProcedure, pageName);
                    if (tb != null && tb.Rows.Count > 0)
                    {
                        RepositoryItemMRUEdit ricbo = new RepositoryItemMRUEdit();
                        ricbo.AutoComplete = true;
                        ricbo.ImmediatePopup = true;
                        //MruEdit是否允许编辑
                        ricbo.TextEditStyle = TextEditStyles.DisableTextEditor;
                        //是否具有删除 绑定的数据源功能
                        ricbo.AllowRemoveMRUItems = false;
                        //ricbo.DropDownRows = 20;
                        //ricbo.Items.Clear();
                        foreach (DataRow row in tb.Rows)
                        {
                            ricbo.Items.Add(row[0].ToString());
                        }
                        ricbo.SelectedValueChanged += new EventHandler(ricbo_SelectedValueChanged);
                        cm.ColumnEdit = ricbo;
                    }
                    #endregion
                }
                else if (entity.optType.ToLower() == "searchlookupedit" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    #region 绑定searchLookUp

                    RepositoryItemSearchLookUpEdit searchLookUp = new RepositoryItemSearchLookUpEdit();
                    //绑定数据源  
                    searchLookUp.DataSource = Data.YLOrdersData.getStoredProcedureData(SqlConn, entity.optStoredProcedure);
                    //设置显示项  
                    searchLookUp.DisplayMember = entity.cmFieldName;
                    searchLookUp.ValueMember = entity.cmFieldName;
                    searchLookUp.ImmediatePopup = true;
                    //设置高度和宽度  
                    searchLookUp.PopupFormSize = new Size(900, 400);
                    searchLookUp.NullText = string.Empty;
                    searchLookUp.TextEditStyle = TextEditStyles.DisableTextEditor;
                    searchLookUp.Validating += new CancelEventHandler(searchLookUp_Validating);

                    cm.ColumnEdit = searchLookUp;
                    #endregion
                }
                else if (entity.optType.ToLower() == "button")
                {
                    RepositoryItemButtonEdit btnFxm = new RepositoryItemButtonEdit();
                    btnFxm.AutoHeight = false;
                    btnFxm.TextEditStyle = TextEditStyles.HideTextEditor;
                    btnFxm.Buttons[0].Kind = ButtonPredefines.Glyph;
                    btnFxm.Buttons[0].Appearance.TextOptions.HAlignment = HorzAlignment.Near;
                    btnFxm.Buttons[0].ImageUri = "Zoom";
                    btnFxm.ButtonClick += new ButtonPressedEventHandler(btnEdit_ButtonClick);
                    cm.ColumnEdit = btnFxm;

                    cm.MaxWidth = entity.cmFieldWidth;
                }
                grid.Columns.Add(cm);
                #endregion
            }
        }
        /// <summary>
        /// 绑定页签
        /// </summary>
        /// <param name="tabPageList"></param>
        /// <param name="gridColumns"></param>
        private void BindTabPages(List<Models.GridPagesModel> tabPageList, IList<Models.GridColumnModel> gridColumns)
        {
            for (int i = 1; i < tabPageList.Count; i++)
            {
                XtraTabPage xpage = new XtraTabPage();
                xpage.Text = tabPageList[i].pageName;
                if (tabPageList[i].pageColor)
                {
                    xpage.Appearance.Header.BackColor = Color.Yellow;
                }
                else
                {
                    xpage.Appearance.Header.BackColor = Color.Green;
                }
                //xpage.Tag = tabPageList[i].PageStoredProcedure;
                xpage.Size = this.PageOrder.Size;
                GridControl gridControl = new GridControl();
                gridControl.Name = tabPageList[i].pageName;
                gridControl.Tag = tabPageList[i].pageStored;
                GridView gridView = new GridView();
                gridView.Tag = tabPageList[i].pageName;
                gridView.GridControl = gridControl;
                gridView.OptionsView.ShowGroupPanel = false;
                gridView.Appearance.HeaderPanel.TextOptions.HAlignment = HorzAlignment.Center;
                gridView.RowHeight = 35;
                //gridView 事件及选项、序号设置
                gridView.OptionsView.ShowGroupPanel = false;
                gridView.OptionsSelection.MultiSelect = true;
                gridView.OptionsSelection.CheckBoxSelectorColumnWidth = 40;
                gridView.OptionsSelection.MultiSelectMode = GridMultiSelectMode.CheckBoxRowSelect;
                gridView.IndicatorWidth = 40;
                gridView.MouseMove += new MouseEventHandler(grid_MouseMove);
                gridView.CustomDrawCell += new RowCellCustomDrawEventHandler(grid_CustomDrawCell);
                gridView.CustomDrawRowIndicator += new RowIndicatorCustomDrawEventHandler(grid_CustomDrawRowIndicator);
                gridView.CellValueChanged += new CellValueChangedEventHandler(grid_CellValueChanged);
                gridView.ValidateRow += new ValidateRowEventHandler(grid_ValidateRow);
                gridView.CustomDrawEmptyForeground += new CustomDrawEventHandler(grid_CustomDrawEmptyForeground);
                gridView.CustomRowCellEdit += new CustomRowCellEditEventHandler(gridOrder_CustomRowCellEdit);
                gridControl.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) | System.Windows.Forms.AnchorStyles.Left) | System.Windows.Forms.AnchorStyles.Right)));
                gridControl.ContextMenuStrip = this.cMenuItems;
                gridControl.Location = this.GridOrder.Location;
                gridControl.Size = this.GridOrder.Size;
                gridControl.MainView = gridView;
                gridControl.ViewCollection.AddRange(new BaseView[] { gridView });

                BindGridColumns(gridView, gridColumns, tabPageList[i].pageName);
                xpage.Controls.Add(gridControl);//添加要增加的控件
                TabOrder.TabPages.Add(xpage);
            }
        }
        //线程绑定数据
        private void BindThreadData()
        {
            for (int i = 1; i < TabOrder.TabPages.Count; i++)
            {
                var gridControl = getGridControlByPages(TabOrder.TabPages[i]);
                if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
                {
                    try
                    { //线程等待
                        DataTable tb = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(), ordId, gridControl.Name, this.Factory);
                        while (!this.IsHandleCreated)
                        {
                        }
                        this.BeginInvoke(new Action(() =>
                        {
                            if (tb != null && tb.Rows.Count == 0)
                            {
                                XtraTabPage tabPage = gridControl.Parent as XtraTabPage;
                                if (tabPage != null)
                                {
                                    if (tabPage.Appearance.Header.BackColor == Color.Yellow)
                                    {
                                        tabPage.Appearance.Header.BackColor = Color.SandyBrown;
                                    }
                                    else
                                    {
                                        tabPage.Appearance.Header.BackColor = Color.BurlyWood;
                                    }
                                }
                            }
                            else if (tb.Columns.Contains("PlateCategory") && tb.Columns.Contains("LegacyPrice"))
                            {
                                var totalModel = new YLOrdPagesTotalModel();
                                totalModel.PageName = gridControl.Name;
                                totalModel.PlateCategory = tb.Rows[0]["PlateCategory"].ToString();
                                if (!pageTotal.Contains(totalModel))
                                {
                                    var value = tb.Compute("SUM(LegacyPrice)", "LegacyPrice > 0");
                                    if (value != null && value != DBNull.Value)
                                    {
                                        totalModel.TotalPrice = Convert.ToDecimal(value);
                                        pageTotal.Add(totalModel);
                                        //获取当前汇总
                                        var curModel = new YLOrdPagesTotalModel();
                                        curModel.PageName = totalModel.PageName;
                                        curModel.PlateCategory = "汇总";
                                        curModel.TotalPrice = pageTotal.Where(p => p.PageName == curModel.PageName && p.PlateCategory != curModel.PlateCategory)
                                        .Sum(p => p.TotalPrice);
                                        if (pageTotal.Contains(curModel))
                                        {
                                            pageTotal.Remove(curModel);
                                        }
                                        pageTotal.Add(curModel);
                                        //获取整单汇总 板件类别的信息
                                        var zpModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == totalModel.PlateCategory);
                                        zpModel.TotalPrice = pageTotal.Where(p => p.PageName != zpModel.PageName && p.PlateCategory == zpModel.PlateCategory)
                                        .Sum(p => p.TotalPrice);

                                        //获取整单汇总 汇总的信息
                                        var zhModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == "汇总");
                                        zhModel.TotalPrice = pageTotal.Where(p => p.PageName != zhModel.PageName && p.PlateCategory == "汇总")
                                        .Sum(p => p.TotalPrice);
                                    }
                                }
                            }
                            gridControl.DataSource = tb;

                        }));
                        if (i == TabOrder.TabPages.Count - 1)
                        {
                            this.BeginInvoke(new Action(() =>
                            {
                                foreach (Control control in this.totalPanel.Controls)
                                {
                                    var tBox = control as TextEdit;
                                    if (tBox != null && tBox.Tag != null)
                                    {
                                        tBox.Text = "0";
                                        var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == tBox.Tag.ToString());
                                        if (tEntity != null)
                                        {
                                            tBox.Text = tEntity.TotalPrice.ToString("0.##");
                                        }
                                    }
                                }
                            }));
                        }
                    }
                    catch (Exception err)
                    {
                    }
                }
            }
        }

        /// <summary>
        /// 获取TabPage下的GridControl
        /// </summary>
        /// <param name="tabPage"></param>
        /// <returns></returns>
        private GridControl getGridControlByPages(XtraTabPage tabPage)
        {
            GridControl gridControl = null;
            foreach (Control control in tabPage.Controls)
            {
                gridControl = control as GridControl;
                if (gridControl != null)
                {
                    break;
                }
            }
            return gridControl;
        }

        /// <summary>
        /// 获取TabPage下的GridView
        /// </summary>
        /// <param name="tabPage"></param>
        /// <returns></returns>
        private GridView getGridViewByPages(XtraTabPage tabPage)
        {
            GridControl gridControl = null;
            foreach (Control control in tabPage.Controls)
            {
                gridControl = control as GridControl;
                if (gridControl != null)
                {
                    return gridControl.MainView as GridView;
                }
            }
            return null;
        }

        /// <summary>
        /// 创建显示ToolTip事件实例
        /// </summary>
        /// <param name="tooltipText"></param>
        /// <returns></returns>
        private ToolTipControllerShowEventArgs CreateShowArgs(string tooltipText)
        {
            ToolTipControllerShowEventArgs args = tipOriginal.CreateShowArgs();
            args.ToolTip = tooltipText;
            return args;
        }
        #endregion

        #region 单元格控件事件
        private void combox_EditValueChanging(object sender, ChangingEventArgs e)
        {
            ComboBoxEdit comBox = sender as ComboBoxEdit;
            if (comBox != null && comBox.Parent != null && comBox.Properties != null && comBox.Properties.Tag != null
                && comBox.Properties.Tag != DBNull.Value)
            {
                if (comBox.Properties.Name != null && !string.IsNullOrEmpty(comBox.Properties.Name))
                {
                    GridControl gControl = comBox.Parent as GridControl;
                    if (gControl != null)
                    {
                        GridView grid = gControl.MainView as GridView;
                        if (grid != null)
                        {
                            var bindValue = grid.GetFocusedRowCellValue(grid.Columns[comBox.Properties.Name]);
                            if (bindValue != null && bindValue != DBNull.Value)
                            {
                                comBox.Properties.Items.Clear();
                                DataTable table = Data.YLOrdersData.getComboBoxData(SqlConn, comBox.Properties.Tag.ToString(), bindValue.ToString(), e.NewValue.ToString());
                                foreach (DataRow row in table.Rows)
                                {
                                    comBox.Properties.Items.Add(row[0].ToString());
                                }
                            }
                        }
                    }
                }
                else
                {
                    comBox.Properties.Items.Clear();
                    DataTable table = Data.YLOrdersData.getComboBoxData(SqlConn, comBox.Properties.Tag.ToString(), e.NewValue.ToString());
                    foreach (DataRow row in table.Rows)
                    {
                        comBox.Properties.Items.Add(row[0].ToString());
                    }
                }
            }
        }
        private void combox_Validating(object sender, CancelEventArgs e)
        {
            ComboBoxEdit comBox = sender as ComboBoxEdit;
            if (comBox != null && comBox.Properties != null && comBox.Parent != null)
            {
                GridControl gControl = comBox.Parent as GridControl;
                if (gControl != null)
                {
                    GridView grid = gControl.MainView as GridView;
                    if (grid != null)
                    {
                        if (string.IsNullOrEmpty(comBox.Text))
                        {
                            if (!((comBox.Properties.Name != null && !string.IsNullOrEmpty(comBox.Properties.Name)) || grid.FocusedColumn.Caption == "备注"))
                            {
                                e.Cancel = true; //验证
                            }
                        }
                        else
                        {
                            if (!comBox.Properties.Items.Contains(comBox.Text))
                            {
                                comBox.Text = String.Empty;
                                e.Cancel = true; //验证
                            }
                            else
                            {
                                if (grid.SelectedRowsCount > 0 && grid.GetSelectedRows().Contains(grid.FocusedRowHandle))
                                {
                                    foreach (int index in grid.GetSelectedRows())
                                    {
                                        if (index != grid.FocusedRowHandle)
                                        {
                                            var value = grid.GetRowCellValue(index, grid.FocusedColumn);
                                            if (value != null && comBox.Text != value.ToString())
                                            {
                                                grid.SetRowCellValue(index, grid.FocusedColumn, comBox.Text);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        private void tBox_Validating(object sender, CancelEventArgs e)
        {
            TextEdit textBox = sender as TextEdit;
            if (textBox != null && !string.IsNullOrEmpty(textBox.Text) && textBox.Parent != null)
            {
                try
                {
                    //var s = Convert.ToDecimal(textBox.Text);
                    #region 联动
                    GridControl gControl = textBox.Parent as GridControl;
                    if (gControl != null)
                    {
                        GridView grid = gControl.MainView as GridView;
                        if (grid != null)
                        {
                            if (grid.SelectedRowsCount > 0 && grid.GetSelectedRows().Contains(grid.FocusedRowHandle))
                            {
                                foreach (int index in grid.GetSelectedRows())
                                {
                                    if (index != grid.FocusedRowHandle)
                                    {
                                        var value = grid.GetRowCellValue(index, grid.FocusedColumn);
                                        if (value != null && textBox.Text != value.ToString())
                                        {
                                            grid.SetRowCellValue(index, grid.FocusedColumn, textBox.Text);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    #endregion
                }
                catch (Exception err)
                {
                    //textBox.Text = err.Message;
                    e.Cancel = true; //验证
                }
            }
        }
        private void ricbo_SelectedValueChanged(object sender, EventArgs e)
        {
            MRUEdit mruComBox = sender as MRUEdit;
            if (mruComBox != null && !string.IsNullOrEmpty(mruComBox.Text))
            {
                GridControl gControl = mruComBox.Parent as GridControl;
                if (gControl != null)
                {
                    GridView grid = gControl.MainView as GridView;
                    if (grid != null && grid.SelectedRowsCount > 0 && grid.GetSelectedRows().Contains(grid.FocusedRowHandle))
                    {
                        foreach (int index in grid.GetSelectedRows())
                        {
                            if (index != grid.FocusedRowHandle)
                            {
                                var value = grid.GetRowCellValue(index, grid.FocusedColumn);
                                if (value != null && mruComBox.Text != value.ToString())
                                {
                                    grid.SetRowCellValue(index, grid.FocusedColumn, mruComBox.Text);
                                }
                            }
                        }
                    }
                }
            }
        }
        private void btnEdit_ButtonClick(object sender, ButtonPressedEventArgs e)
        {
            ButtonEdit btn = sender as ButtonEdit;
            if (!string.IsNullOrEmpty(btn.Text))
            {
                if (File.Exists(btn.Text))
                {
                    System.Diagnostics.Process.Start(btn.Text);
                }
                else
                {
                    MessageBox.Show("找不到文件" + btn.Text, "信息提示");
                }
            }
            else
            {
                MessageBox.Show("无该FXM文件", "信息提示");
            }
        }
        private void searchLookUp_Validating(object sender, CancelEventArgs e)
        {
            SearchLookUpEdit searchLook = sender as SearchLookUpEdit;
            if (searchLook != null && searchLook.Properties != null && searchLook.Parent != null)
            {
                if (string.IsNullOrEmpty(searchLook.Text))
                {
                    e.Cancel = true;
                }
                else
                {
                    GridControl gControl = searchLook.Parent as GridControl;
                    if (gControl != null)
                    {
                        GridView gv = gControl.MainView as GridView;
                        if (gv != null)
                        {
                            DataTable table = searchLook.Properties.DataSource as DataTable;
                            DataRow[] rows = table.Select(string.Format("{0}='{1}'", searchLook.Properties.DisplayMember, searchLook.Text));
                            if (rows != null && rows.Length > 0)
                            {
                                DataRow row = rows[0];
                                if (gv.SelectedRowsCount > 0 && gv.GetSelectedRows().Contains(gv.FocusedRowHandle))
                                {
                                    foreach (int index in gv.GetSelectedRows())
                                    {
                                        var value = gv.GetRowCellValue(index, gv.Columns["actions"]);
                                        if (value != null && value != DBNull.Value)
                                        {
                                            if (value.ToString() != ((int)Common.ActionsType.add).ToString())
                                            {
                                                if (searchLook.Properties.DisplayMember.ToLower() == "itmitemnumber")
                                                {
                                                    gv.SetRowCellValue(index, gv.Columns["actions"],
                                                    Common.ActionsType.replace);
                                                }
                                                else
                                                {
                                                    gv.SetRowCellValue(index, gv.Columns["actions"],
                                                     Common.ActionsType.update);
                                                }
                                            }
                                        }
                                        else
                                        {
                                            if (searchLook.Properties.DisplayMember.ToLower() == "itmitemnumber")
                                            {
                                                gv.SetRowCellValue(index, gv.Columns["actions"],
                                                    Common.ActionsType.replace);
                                            }
                                            else
                                            {
                                                gv.SetRowCellValue(index, gv.Columns["actions"],
                                                    Common.ActionsType.update);
                                            }
                                        }
                                        foreach (DataColumn cm in table.Columns)
                                        {
                                            gv.SetRowCellValue(index, gv.Columns[cm.ColumnName], row[cm.ColumnName]);
                                        }

                                    }
                                }
                                else
                                {
                                    var value = gv.GetFocusedRowCellValue(gv.Columns["actions"]);
                                    if (value == null || value == DBNull.Value)
                                    {
                                        if (searchLook.Properties.DisplayMember.ToLower() == "itmitemnumber")
                                        {
                                            gv.SetFocusedRowCellValue(gv.Columns["actions"], Common.ActionsType.replace);
                                        }
                                        else
                                        {
                                            gv.SetFocusedRowCellValue(gv.Columns["actions"], Common.ActionsType.update);
                                        }
                                    }
                                    else
                                    {
                                        if (value.ToString() != ((int)Common.ActionsType.add).ToString())
                                        {
                                            if (searchLook.Properties.DisplayMember.ToLower() == "itmitemnumber")
                                            {
                                                gv.SetFocusedRowCellValue(gv.Columns["actions"],
                                                    Common.ActionsType.replace);
                                            }
                                            else
                                            {
                                                gv.SetFocusedRowCellValue(gv.Columns["actions"],
                                                     Common.ActionsType.update);
                                            }
                                        }
                                    }
                                    foreach (DataColumn cm in table.Columns)
                                    {
                                        gv.SetFocusedRowCellValue(gv.Columns[cm.ColumnName], row[cm.ColumnName]);
                                    }

                                }
                            }
                        }
                    }
                }

            }
        }

        private void curBox_Validating(object sender, CancelEventArgs e)
        {
            TextEdit textBox = sender as TextEdit;
            if (textBox != null && textBox.Tag != null)
            {
                decimal value = 0;
                if (textBox.EditValue != null && textBox.EditValue != DBNull.Value)
                {
                    value = Convert.ToDecimal(textBox.EditValue);
                }
                var curEntity = pageTotal.Find(p => p.PageName == this.TabOrder.SelectedTabPage.Text &&
                                                    p.PlateCategory == textBox.Tag.ToString());
                if (curEntity != null)
                {
                    if (curEntity.TotalPrice != value)
                    {
                        curEntity.TotalPrice = value;
                        setPanelControl(textBox.Tag.ToString(), value);
                    }
                }
                else
                {
                    if (value != 0)
                    {
                        var entity = new YLOrdPagesTotalModel();
                        entity.PageName = this.TabOrder.SelectedTabPage.Text;
                        entity.PlateCategory = textBox.Tag.ToString();
                        entity.TotalPrice = value;
                        pageTotal.Add(entity);
                        setPanelControl(textBox.Tag.ToString(), value);
                    }
                }
            }
        }

        private void totalBox_Validating(object sender, CancelEventArgs e)
        {
            TextEdit textBox = sender as TextEdit;
            if (textBox != null && textBox.Tag != null)
            {
                decimal value = 0;
                if (textBox.EditValue != null && textBox.EditValue != DBNull.Value)
                {
                    value = Convert.ToDecimal(textBox.EditValue);
                }
                var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" &&
                                                  p.PlateCategory == textBox.Tag.ToString());
                if (tEntity != null)
                {
                    if (tEntity.TotalPrice != value)
                    {
                        tEntity.TotalPrice = value;
                        //切换页签后，绑定整单统计信息
                        foreach (Control control in this.totalPanel.Controls)
                        {
                            var tBox = control as TextEdit;
                            if (tBox != null && tBox.Tag != null)
                            {
                                if (tBox.Tag.ToString() == "汇总")
                                {
                                    var price = pageTotal.Where(p =>
                                             p.PageName == "整单汇总"
                                            && p.PlateCategory != "汇总" && p.PlateCategory != textBox.Tag.ToString())
                                      .Sum(p => p.TotalPrice);
                                    var totalEntity = pageTotal.Find(p => p.PageName == "整单汇总" &&
                                                  p.PlateCategory == "汇总");
                                    if (totalEntity != null)
                                    {
                                        totalEntity.TotalPrice = price + tEntity.TotalPrice + value;
                                    }
                                    tBox.Text = (price + value).ToString("0.##");
                                }
                            }
                        }
                    }
                }
            }
        }

        #endregion

        #region GridView事件
        /// <summary>
        /// 没绑定数据源时
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void grid_CustomDrawEmptyForeground(object sender, CustomDrawEventArgs e)
        {
            GridView gv = sender as GridView;
            if (gv != null)
            {
                if (gv.DataSource == null)
                {
                    string str = "数据正努力加载中，请稍等...";
                    Font f = new Font("宋体", 10, FontStyle.Bold);
                    Rectangle r = new Rectangle(e.Bounds.Left + 5, e.Bounds.Top + 5, e.Bounds.Width - 5, e.Bounds.Height - 5);
                    e.Graphics.DrawString(str, f, Brushes.Black, r);
                }
                else if (gv.RowCount == 0)
                {
                    string str = "没有查询到你所想要的数据!";
                    Font f = new Font("宋体", 10, FontStyle.Bold);
                    Rectangle r = new Rectangle(e.Bounds.Left + 5, e.Bounds.Top + 5, e.Bounds.Width - 5, e.Bounds.Height - 5);
                    e.Graphics.DrawString(str, f, Brushes.Black, r);
                }
            }
        }
        //行号设置  
        private void grid_CustomDrawRowIndicator(object sender, RowIndicatorCustomDrawEventArgs e)
        {
            if (e.Info.IsRowIndicator && e.RowHandle > -1)
            {
                e.Info.DisplayText = (e.RowHandle + 1).ToString();
            }
        }
        private void grid_MouseMove(object sender, MouseEventArgs e)
        {
            // 获取鼠标焦点
            GridView grid = sender as GridView;
            GridHitInfo hi = grid.CalcHitInfo(new Point(e.X, e.Y));
            // 如果鼠标不是在行上.或者不在列上
            if (hi.RowHandle < 0 || hi.Column == null)
            {
                return;
            }
            if (hi.Column.Tag != null)
            {
                var curCellValue = grid.GetRowCellValue(hi.RowHandle, hi.Column.FieldName);
                var rawValue = grid.GetRowCellValue(hi.RowHandle, hi.Column.Tag.ToString());
                if (curCellValue != null && rawValue != null && !string.IsNullOrEmpty(rawValue.ToString()) &&
                    curCellValue.ToString() != rawValue.ToString())
                {
                    ToolTipControllerShowEventArgs args = CreateShowArgs(rawValue.ToString());
                    // 设置ToolTip标题
                    //args.Title = "原始数据";
                    // 显示ToolTip 这里不可以用控件的坐标.要用屏幕的坐标Control.MousePosition
                    tipOriginal.ShowHint(args, System.Windows.Forms.Control.MousePosition);
                }
                else
                {
                    tipOriginal.HideHint();
                }
            }
            else
            {
                tipOriginal.HideHint();
            }
        }
        private void grid_CustomDrawCell(object sender, RowCellCustomDrawEventArgs e)
        {
            if (e.Column.Visible)
            {
                GridView grid = sender as GridView;
                var actValue = grid.GetRowCellValue(e.RowHandle, grid.Columns["actions"]);
                if (actValue != null && actValue != DBNull.Value)
                {
                    if (actValue.ToString() == ((int)Common.ActionsType.add).ToString() || actValue.ToString() == ((int)Common.ActionsType.sqlAdd).ToString())
                    {
                        e.Appearance.BackColor = Color.BurlyWood;
                    }
                    else if (actValue.ToString() == ((int)Common.ActionsType.replace).ToString() ||
                             actValue.ToString() == ((int)Common.ActionsType.sqlReplace).ToString())
                    {
                        e.Appearance.BackColor = Color.Moccasin;
                    }
                    else if ((actValue.ToString() == ((int)Common.ActionsType.update).ToString() ||
                              actValue.ToString() == ((int)Common.ActionsType.sqlUpdate).ToString()) &&
                             e.Column.Tag != null && e.Column.Tag != DBNull.Value)
                    {
                        var rawValue = grid.GetRowCellValue(e.RowHandle, e.Column.Tag.ToString());
                        if (rawValue != null)
                        {
                            if (rawValue == DBNull.Value && !String.IsNullOrEmpty(e.CellValue.ToString()))
                            {
                                e.Appearance.BackColor = Color.Yellow;
                            }
                            else
                            {
                                if (e.CellValue.ToString() != rawValue.ToString())
                                {
                                    e.Appearance.BackColor = Color.Yellow;
                                }
                            }
                        }
                    }
                }
            }
        }
        private void grid_CellValueChanged(object sender, CellValueChangedEventArgs e)
        {
            if (e.Column.OptionsColumn.AllowEdit)
            {
                GridView grid = sender as GridView;
                if (grid != null)
                {
                    try
                    {
                        if (grid.Tag != null && !string.IsNullOrEmpty(grid.Tag.ToString()) &&
                        (grid.Tag.ToString() == "普通柜身" || grid.Tag.ToString() == "实木柜身"))
                        {
                            #region 尺寸联动
                            if (e.Column.FieldName == "dimFX" || e.Column.FieldName == "dimFY" ||
                                e.Column.FieldName == "dimFZ" || e.Column.FieldName == "edgeCode" || e.Column.FieldName == "topSurCode")
                            {
                                var dimFX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFX"]);
                                var dimFY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFY"]);
                                var dimFZ = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFZ"]);
                                var edgeCode = grid.GetRowCellValue(e.RowHandle, grid.Columns["edgeCode"]);
                                var topSurCode = grid.GetRowCellValue(e.RowHandle, grid.Columns["topSurCode"]);
                                var WenLi = grid.GetRowCellValue(e.RowHandle, grid.Columns["WenLi"]);
                                if (dimFX != null && dimFX != DBNull.Value && dimFY != null && dimFY != DBNull.Value && dimFZ != null && dimFZ != DBNull.Value && edgeCode != null
                                    && edgeCode != DBNull.Value && topSurCode != null && topSurCode != DBNull.Value && WenLi != null && WenLi != DBNull.Value)
                                {
                                    try
                                    {
                                        double dimCX = 0, dimCY = 0;
                                        Data.YLOrdersData.getMOrdItemDimensions(SqlConn, Convert.ToDecimal(dimFX), Convert.ToDecimal(dimFY), Convert.ToDecimal(dimFZ), edgeCode.ToString(), topSurCode.ToString(), Convert.ToInt16(WenLi), ref dimCX, ref dimCY);
                                        if (dimCX != null && dimCX != 0 && dimCY != null && dimCY != 0)
                                        {
                                            grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], dimCX);
                                            grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], dimCY);
                                            grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCZ"], dimFZ);
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                            }
                            #endregion
                        }
                        else
                        {
                            #region 计算面积

                            if (grid.Columns["Area"] != null)
                            {
                                if (e.Column.FieldName == "dimFX" || e.Column.FieldName == "dimFY")
                                {
                                    var dimFX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFX"]);
                                    var dimFY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFY"]);
                                    if (dimFX != null && dimFX != DBNull.Value && dimFY != null && dimFY != DBNull.Value)
                                    {
                                        var areaValue = Math.Round(
                                            Convert.ToDecimal(dimFX) * Convert.ToDecimal(dimFY) / 1000000, 3);
                                        grid.SetRowCellValue(e.RowHandle, grid.Columns["Area"], areaValue);
                                    }
                                }
                            }
                            if (grid.Columns["cArea"] != null)
                            {
                                if (e.Column.FieldName == "dimCX" || e.Column.FieldName == "dimCY")
                                {
                                    var dimCX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCX"]);
                                    var dimCY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCY"]);
                                    if (dimCX != null && dimCX != DBNull.Value && dimCY != null && dimCY != DBNull.Value)
                                    {
                                        var areaValue = Math.Round(
                                            Convert.ToDecimal(dimCX) * Convert.ToDecimal(dimCY) / 1000000, 3);
                                        grid.SetRowCellValue(e.RowHandle, grid.Columns["cArea"], areaValue);
                                    }
                                }
                            }

                            #endregion
                        }
                        if (this.lblOtp.Text == "遗留单" && grid.Columns["LegacyPrice"] != null && grid.Columns["Price"] != null)
                        {
                            if (grid.Tag != null && !string.IsNullOrEmpty(grid.Tag.ToString()) &&
                                (grid.Tag.ToString() == "普通五金" || grid.Tag.ToString() == "实木五金"))
                            {
                                #region 五金
                                if (grid.Columns["oriReqQty"] != null)
                                {
                                    if (e.Column.FieldName == "oriReqQty" || e.Column.FieldName == "Price")
                                    {
                                        var oriReqQty = grid.GetRowCellValue(e.RowHandle, grid.Columns["oriReqQty"]);
                                        var Price = grid.GetRowCellValue(e.RowHandle, grid.Columns["Price"]);
                                        if (oriReqQty != null && oriReqQty != DBNull.Value && Price != null && Price != DBNull.Value)
                                        {
                                            if (Convert.ToDecimal(Price) > 0)
                                            {
                                                var LegacyPrice = Math.Round(Convert.ToDecimal(oriReqQty) * Convert.ToDecimal(Price), 0);
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], LegacyPrice);
                                            }
                                        }
                                        //else
                                        //{
                                        //    grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], 0);
                                        //}
                                    }
                                }
                                #endregion
                            }
                            else
                            {
                                if (grid.Columns["dimFX"] != null && grid.Columns["dimFY"] != null)
                                {
                                    #region 使用完工尺寸计算
                                    if (e.Column.FieldName == "dimFX" || e.Column.FieldName == "dimFY" ||
                                        e.Column.FieldName == "Price")
                                    {
                                        var dimFX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFX"]);
                                        var dimFY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFY"]);
                                        var Price = grid.GetRowCellValue(e.RowHandle, grid.Columns["Price"]);
                                        if (dimFX != null && dimFX != DBNull.Value && dimFY != null && dimFY != DBNull.Value && Price != null && Price != DBNull.Value && Convert.ToDecimal(Price) > 0)
                                        {
                                            var LegacyPrice = Math.Round(Convert.ToDecimal(dimFX) * Convert.ToDecimal(dimFY) * Convert.ToDecimal(Price) / 1000000, 0);
                                            grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], LegacyPrice);
                                        }
                                        //else
                                        //{
                                        //    grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], 0);
                                        //}
                                    }
                                    #endregion
                                }
                                else
                                {
                                    #region 若界面未显示完工尺寸，则使用裁切尺寸计算
                                    if (grid.Columns["dimCX"] != null && grid.Columns["dimCY"] != null)
                                    {
                                        if (e.Column.FieldName == "dimCX" || e.Column.FieldName == "dimCY" ||
                                            e.Column.FieldName == "Price")
                                        {
                                            var dimCX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCX"]);
                                            var dimCY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCY"]);
                                            var Price = grid.GetRowCellValue(e.RowHandle, grid.Columns["Price"]);
                                            if (dimCX != null && dimCX != DBNull.Value && dimCY != null &&
                                                dimCY != DBNull.Value && Price != null && Price != DBNull.Value
                                                && Convert.ToDecimal(Price) > 0)
                                            {
                                                var LegacyPrice = Math.Round(
                                                        Convert.ToDecimal(dimCX) * Convert.ToDecimal(dimCY) *
                                                        Convert.ToDecimal(Price) / 1000000, 0);
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], LegacyPrice);
                                            }
                                            //else
                                            //{
                                            //    grid.SetRowCellValue(e.RowHandle, grid.Columns["LegacyPrice"], 0);
                                            //}
                                        }
                                    }
                                    #endregion
                                }
                            }
                        }
                        #region 行的状态
                        var actValue = grid.GetRowCellValue(e.RowHandle, grid.Columns["actions"]);
                        if (actValue != null)
                        {
                            if (actValue == DBNull.Value || actValue.ToString() == ((int)Common.ActionsType.defualt).ToString()
                                || actValue.ToString() == ((int)Common.ActionsType.sqlUpdate).ToString()
                                || actValue.ToString() == ((int)Common.ActionsType.sqlAdd).ToString()
                                || actValue.ToString() == ((int)Common.ActionsType.sqlReplace).ToString())
                            {
                                grid.SetRowCellValue(e.RowHandle, grid.Columns["actions"], (int)Common.ActionsType.update);
                            }
                        }
                        #endregion
                    }
                    catch (Exception err)
                    {
                        throw new Exception("修改异常！" + err.Message);
                    }

                }
            }

        }

        RepositoryItemButtonEdit _disItemBtn;
        private void gridOrder_CustomRowCellEdit(object sender, CustomRowCellEditEventArgs e)
        {
            if (e.Column.ColumnEdit != null && e.Column.ColumnEdit.EditorTypeName == "ButtonEdit")
            {
                if (e.CellValue == null || e.CellValue == DBNull.Value || string.IsNullOrEmpty(e.CellValue.ToString().Trim()))
                {
                    _disItemBtn = (RepositoryItemButtonEdit)e.RepositoryItem.Clone();
                    _disItemBtn.Buttons[0].Enabled = false;
                    e.RepositoryItem = _disItemBtn;
                }

            }
        }
        private void grid_ValidateRow(object sender, ValidateRowEventArgs e)
        {
            GridView grid = sender as GridView;
            if (grid != null && grid.Tag != null && !string.IsNullOrEmpty(grid.Tag.ToString()) && grid.DataSource != null)
            {
                foreach (GridColumn cm in grid.Columns)
                {
                    #region 验证列
                    if (cm.OptionsColumn.AllowEdit)
                    {
                        if (cm.FieldName == "oriReqQty" || cm.FieldName == "itmDescription")
                        {
                            var value = grid.GetRowCellValue(e.RowHandle, cm);
                            if (value == null || value == DBNull.Value || string.IsNullOrEmpty(value.ToString().Trim()))
                            {
                                e.Valid = false;
                                e.ErrorText = cm.Caption + " 为必填项！";
                            }
                        }
                        else
                        {
                            if (cm.ColumnEdit != null && !string.IsNullOrEmpty(cm.ColumnEdit.Name))
                            {
                                var value = grid.GetRowCellValue(e.RowHandle, cm);
                                if (value == null || value == DBNull.Value || string.IsNullOrEmpty(value.ToString().Trim()))
                                {
                                    e.Valid = false;
                                    e.ErrorText = cm.Caption + " 为必填项！";
                                }
                            }
                        }
                    }
                    #endregion
                }
                var pageName = grid.Tag.ToString();
                var dv = grid.DataSource as DataView;
                if (dv != null && dv.Count > 0 && dv.Table.Columns.Contains("PlateCategory") &&
                    dv.Table.Columns.Contains("LegacyPrice"))
                {
                    DataTable table = dv.ToTable(false, "PlateCategory", "LegacyPrice");
                    foreach (Control control in this.curPanel.Controls)
                    {
                        #region 计算价格汇总
                        var tBox = control as TextEdit;
                        if (tBox != null && tBox.Tag != null)
                        {
                            tBox.Text = "0";
                            if (tBox.Tag.ToString() == "汇总")
                            {
                                var entity = new YLOrdPagesTotalModel();
                                entity.PageName = pageName;
                                entity.PlateCategory = tBox.Tag.ToString();
                                if (pageTotal.Contains(entity))
                                {
                                    pageTotal.Remove(entity);
                                }
                                DataRow[] rows = table.Select("LegacyPrice IS NOT NULL");
                                if (rows.Count() > 0)
                                {
                                    entity.TotalPrice = rows.Sum(x => Convert.ToDecimal(x.ItemArray[1]));
                                    pageTotal.Add(entity);
                                    tBox.Text = entity.TotalPrice.ToString("0.##");
                                }
                            }
                            else
                            {
                                var entity = new YLOrdPagesTotalModel();
                                entity.PageName = pageName;
                                entity.PlateCategory = tBox.Tag.ToString();
                                if (pageTotal.Contains(entity))
                                {
                                    pageTotal.Remove(entity);
                                }
                                DataRow[] rows = table.Select("PlateCategory='" + tBox.Tag + "' AND LegacyPrice IS NOT NULL");
                                if (rows.Count() > 0)
                                {
                                    entity.TotalPrice = rows.Sum(x => Convert.ToDecimal(x.ItemArray[1]));
                                    pageTotal.Add(entity);
                                    tBox.Text = entity.TotalPrice.ToString("0.##");
                                }
                            }
                        }
                        #endregion
                    }
                    //赋值整单汇总
                    string tPageName = "整单汇总";
                    foreach (Control control in this.totalPanel.Controls)
                    {
                        var tBox = control as TextEdit;
                        if (tBox != null && tBox.Tag != null)
                        {
                            var tPrice = pageTotal.Where(p => p.PageName != tPageName && p.PlateCategory == tBox.Tag.ToString())
                                .Sum(p => p.TotalPrice);
                            var tEntity = pageTotal.Find(p => p.PageName == tPageName && p.PlateCategory == tBox.Tag.ToString());
                            if (tEntity != null)
                            {
                                tEntity.TotalPrice = tPrice;
                                tBox.Text = tPrice.ToString("0.##");
                            }
                        }
                    }
                }
            }
        }
        #endregion

        #region 右键菜单事件
        private void MenuAdd_Click(object sender, EventArgs e)
        {
            GridView gv = getGridViewByPages(TabOrder.SelectedTabPage);
            if (gv != null)
            {
                if (gv.SelectedRowsCount > 0)
                {
                    foreach (int index in gv.GetSelectedRows())
                    {
                        gv.AddNewRow();
                        DataRow dr = gv.GetDataRow(index);
                        foreach (DataColumn cm in dr.Table.Columns)
                        {
                            if (cm.ColumnName == "actions")
                            {
                                gv.SetFocusedRowCellValue(gv.Columns[cm.ColumnName], (int)Common.ActionsType.add);
                            }
                            else
                            {
                                gv.SetFocusedRowCellValue(gv.Columns[cm.ColumnName], dr[cm.ColumnName]);
                            }
                        }
                    }
                }
                else
                {
                    gv.AddNewRow();
                    gv.SetFocusedRowCellValue(gv.Columns["actions"], (int)Common.ActionsType.add);
                }
            }
        }
        private void MenuDel_Click(object sender, EventArgs e)
        {
            GridView gv = getGridViewByPages(TabOrder.SelectedTabPage);
            if (gv != null)
            {
                if (gv.GetSelectedRows().Count() > 0)
                {
                    if (MessageBox.Show("你确定要删除选中的记录吗？", "删除提示",
                        MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
                        MessageBoxDefaultButton.Button2, 0, false) == DialogResult.Yes)
                    {
                        foreach (int index in gv.GetSelectedRows())
                        {
                            DataRow dr = gv.GetDataRow(index);
                            if (dr["actions"].ToString() != ((int)Common.ActionsType.add).ToString())
                            {
                                DataRow addRow = saveTable.NewRow();
                                foreach (DataColumn cm in dr.Table.Columns)
                                {
                                    if (saveTable.Columns.Contains(cm.ColumnName))
                                    {
                                        addRow[cm.ColumnName] = dr[cm.ColumnName];
                                    }
                                }
                                addRow["actions"] = (int)Common.ActionsType.sqlRemove; ;
                                saveTable.Rows.Add(addRow);
                            }
                        }
                        gv.DeleteSelectedRows();
                    }
                }
                else
                {
                    MessageBox.Show("请选择要删除的项！", "提示");
                }
            }
        }
        private void MenuRefresh_Click(object sender, EventArgs e)
        {
            GridControl gridControl = getGridControlByPages(TabOrder.SelectedTabPage);
            if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
            {
                try
                {
                    DataTable table = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(), ordId, gridControl.Name, Factory);
                    if (table != null && table.Rows.Count == 0)
                    {
                        TabOrder.SelectedTabPage.Appearance.Header.BackColor = Color.BurlyWood;
                    }
                    gridControl.DataSource = table;
                }
                catch (Exception err)
                {
                    MessageBox.Show("获取数据失败！" + err.Message, "信息提示");
                }

                saveTable.Clear();
            }
        }
        #endregion

        #region 按钮事件

        private void btnSubmit_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("是否保存当前页签操作数据", "信息提示", MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
                MessageBoxDefaultButton.Button2, 0, false) == DialogResult.Yes)
            {
                Save(this.TabOrder.SelectedTabPage);
            }
            else
            {
                //刷新
                saveTable.Clear();
                GridControl grid = getGridControlByPages(TabOrder.SelectedTabPage);
                if (grid != null && grid.Tag != null)
                {
                    grid.DataSource = Data.YLOrdersData.getStoredData(SqlConn, grid.Tag.ToString(), ordId, TabOrder.SelectedTabPage.Text, Factory);
                }
            }
        }
        #endregion

        private void tabControl_SelectedPageChanged(object sender, TabPageChangedEventArgs e)
        {
            #region 获取页签数据
            GridControl gridControl = getGridControlByPages(e.PrevPage);
            if (gridControl != null && gridControl.Parent != null)
            {
                DataTable table = gridControl.DataSource as DataTable;
                if (table != null && table.Rows.Count > 0)
                {
                    #region 获取控件数据
                    DataRow[] drArr = table.Select("actions IN(5,6,8)"); //查询
                    foreach (DataRow row in drArr)
                    {
                        DataRow addRow = saveTable.NewRow();
                        foreach (DataColumn cm in row.Table.Columns)
                        {
                            if (saveTable.Columns.Contains(cm.ColumnName))
                            {
                                if (cm.ColumnName == "actions" && row[cm.ColumnName] != null)
                                {
                                    #region 转换操作类型
                                    if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.replace).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlReplace;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.add).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlAdd;
                                    }
                                    else if (row[cm.ColumnName].ToString() ==
                                             ((int)Common.ActionsType.update).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlUpdate;
                                    }
                                    #endregion
                                }
                                addRow[cm.ColumnName] = row[cm.ColumnName];
                            }
                        }
                        saveTable.Rows.Add(addRow);
                    }
                    #endregion
                }
            }
            #endregion

            if (this.curPanel.Tag != null || this.saveTable.Rows.Count > 0)
            {
                if (MessageBox.Show("是否保存前页签的操作数据", "信息提示",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
                    MessageBoxDefaultButton.Button2, 0, false) == DialogResult.Yes)
                {
                    #region 处理数据
                    try
                    {
                        #region 获取汇总信息
                        //List<YLOrdPagesTotalModel> totalList = new List<YLOrdPagesTotalModel>();
                        //1、获取当前页签汇总信息
                        foreach (Control control in this.curPanel.Controls)
                        {
                            var tBox = control as TextEdit;
                            if (tBox != null && tBox.Tag != null && !string.IsNullOrEmpty(tBox.Text))
                            {
                                var entity = new YLOrdPagesTotalModel();
                                entity.PageName = e.PrevPage.Text;
                                entity.PlateCategory = tBox.Tag.ToString();
                                entity.TotalPrice = Convert.ToDecimal(tBox.Text);
                                //totalList.Add(entity);
                                if (pageTotal.Contains(entity))
                                {
                                    pageTotal.Remove(entity);
                                }
                                //若价格为0，则不添加
                                if (entity.TotalPrice > 0)
                                {
                                    pageTotal.Add(entity);
                                }
                            }
                        }
                        //2、获取整单汇总信息
                        foreach (Control control in this.totalPanel.Controls)
                        {
                            var tBox = control as TextEdit;
                            if (tBox != null && tBox.Tag != null && !string.IsNullOrEmpty(tBox.Text))
                            {
                                var entity = new YLOrdPagesTotalModel();
                                entity.PageName = "整单汇总";
                                entity.PlateCategory = tBox.Tag.ToString();
                                entity.TotalPrice = Convert.ToDecimal(tBox.Text);
                                //totalList.Add(entity);
                                if (pageTotal.Contains(entity))
                                {
                                    pageTotal.Remove(entity);
                                }
                                //若价格为0，则不添加
                                if (entity.TotalPrice > 0)
                                {
                                    pageTotal.Add(entity);
                                }
                            }
                        }
                        #endregion

                        DataTable table = Common.CommonHelper.ConvertToTable<YLOrdPagesTotalModel>(pageTotal);
                        Data.YLOrdersData.utlYLOrdEditingBatch(SqlConn, ordId, e.PrevPage.Text, this.ordSource,
                            saveTable, table);
                        MessageBox.Show("保存成功！", "提示");
                        if (this.saveTable.Rows.Count > 0)
                        {
                            e.PrevPage.Appearance.Header.BackColor = Color.Yellow;
                            gridControl.DataSource = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(),
                                ordId, gridControl.Name, Factory);
                            //保存后清空
                            saveTable.Clear();
                        }
                        //if (totalList.Count > 0)
                        //{
                        //this.pageTotal = Data.YLOrdersData.getYLOrdPagesTotalData(SqlConn, ordId).ToList();
                        //}
                    }
                    catch (Exception err)
                    {
                        //保存后清空
                        saveTable.Clear();
                        MessageBox.Show("保存失败！" + err.Message, "提示");
                    }

                    #endregion
                }
                else
                {   //保存后清空
                    this.saveTable.Clear();
                }
                this.curPanel.Tag = null;
            }
            bindPanelControl(e.Page.Text);
        }
        private void btnDelAll_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("是否保存所选择操作数据！", "信息提示",
                MessageBoxButtons.YesNo, MessageBoxIcon.Warning,
                MessageBoxDefaultButton.Button2, 0, false) == DialogResult.Yes)
            {
                DataTable table = Data.YLOrdersData.getYLOrdDelTypeColumns(SqlConn);
                foreach (XtraTabPage page in this.TabOrder.TabPages)
                {
                    #region 获取处理数据
                    GridView gv = getGridViewByPages(page);
                    if (gv != null && gv.SelectedRowsCount > 0)
                    {
                        foreach (int index in gv.GetSelectedRows())
                        {
                            DataRow dr = gv.GetDataRow(index);
                            DataRow addRow = table.NewRow();
                            foreach (DataColumn cm in table.Columns)
                            {
                                if (dr.Table.Columns.Contains(cm.ColumnName))
                                {
                                    addRow[cm.ColumnName] = dr[cm.ColumnName];
                                }
                            }
                            table.Rows.Add(addRow);
                        }
                        if (gv.SelectedRowsCount != gv.RowCount)
                        {
                            page.Appearance.Header.BackColor = Color.Yellow;
                        }
                    }
                    #endregion
                }
                if (table != null && table.Rows.Count > 0)
                {
                    bool bSubmit = true;
                    try
                    {
                        Data.YLOrdersData.DelYLOrdBOMBatch(SqlConn, ordId, table);
                        MessageBox.Show("批量挑板删除板功能，数据提交成功！", "提示");
                    }
                    catch (Exception err)
                    {
                        bSubmit = false;
                        int index = err.Message.IndexOf("\r\n");
                        if (index > 0)
                        {
                            MessageBox.Show("批量挑板删除板功能，数据提交失败！" + err.Message.Substring(0, index), "提示");
                        }
                        else
                        {
                            MessageBox.Show("批量挑板删除板功能，数据提交失败！" + err.Message, "提示");
                        }
                    }
                    if (bSubmit)
                    {
                        //1、更新当前页签数据
                        #region 挑板删板操作成功后，数据处理
                        if (this.TabOrder.SelectedTabPage.Appearance.Header.BackColor != Color.BurlyWood)
                        {
                            var gridControl = getGridControlByPages(this.TabOrder.SelectedTabPage);
                            if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
                            {
                                DataTable tb = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(), ordId, gridControl.Name, this.Factory);
                                if (tb != null && tb.Rows.Count == 0)
                                {
                                    //操作后数据为空时
                                    var curList = pageTotal.Where(p => p.PageName == GridOrder.Name);
                                    foreach (var cur in curList)
                                    {
                                        cur.TotalPrice = 0;
                                    }
                                    //整单汇总
                                    var totalList = pageTotal.Where(p => p.PageName == "整单汇总");
                                    foreach (var tl in totalList)
                                    {
                                        tl.TotalPrice = pageTotal.Where(p => p.PageName != tl.PageName && p.PlateCategory == tl.PlateCategory)
                                                .Sum(p => p.TotalPrice);
                                    }
                                    this.TabOrder.SelectedTabPage.Appearance.Header.BackColor = Color.SandyBrown;
                                }
                                else if (tb != null && tb.Columns.Contains("PlateCategory") && tb.Columns.Contains("LegacyPrice"))
                                {
                                    DataTable tbPlateCategory = tb.DefaultView.ToTable(true, "PlateCategory");
                                    foreach (DataRow row in tbPlateCategory.Rows)
                                    {
                                        if (row[0] != null && row[0] != DBNull.Value && !string.IsNullOrEmpty(row[0].ToString()))
                                        {
                                            var curModel = pageTotal.Find(p => p.PageName == GridOrder.Name && p.PlateCategory == row[0].ToString());
                                            if (curModel != null)
                                            {
                                                curModel.TotalPrice = 0;
                                                var value = tb.Compute("SUM(LegacyPrice)", "PlateCategory='" + row[0] + "' AND LegacyPrice > 0 ");
                                                if (value != null && value != DBNull.Value)
                                                {
                                                    curModel.TotalPrice = Convert.ToDecimal(value);
                                                }
                                            }
                                            //整单汇总
                                            var totalModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == row[0].ToString());
                                            if (totalModel != null)
                                            {
                                                totalModel.TotalPrice = pageTotal.Where(p =>
                                                             p.PageName != totalModel.PageName &&
                                                             p.PlateCategory == totalModel.PlateCategory).Sum(p => p.TotalPrice);
                                            }
                                        }
                                    }
                                    var curTotalModel = pageTotal.Find(p => p.PageName == GridOrder.Name && p.PlateCategory == "汇总");
                                    if (curTotalModel != null)
                                    {
                                        curTotalModel.TotalPrice = pageTotal.Where(p => p.PageName == GridOrder.Name && p.PlateCategory != "汇总").Sum(p => p.TotalPrice);
                                    }
                                    var tModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == "汇总");
                                    if (tModel != null)
                                    {
                                        tModel.TotalPrice = pageTotal.Where(p =>
                                                     p.PageName != tModel.PageName &&
                                                     p.PlateCategory == tModel.PlateCategory).Sum(p => p.TotalPrice);
                                    }
                                    //切换页签后，绑定当前统计信息
                                    foreach (Control control in this.curPanel.Controls)
                                    {
                                        var tBox = control as TextEdit;
                                        if (tBox != null && tBox.Tag != null)
                                        {
                                            tBox.Text = "0";
                                            var tEntity = pageTotal.Find(p => p.PageName == GridOrder.Name && p.PlateCategory == tBox.Tag.ToString());
                                            if (tEntity != null)
                                            {
                                                tBox.Text = tEntity.TotalPrice.ToString("0.##");
                                            }
                                        }
                                    }
                                }
                                gridControl.DataSource = tb;
                            }
                        }
                        //2、线程更新其他页签数据
                        //后台加载其他页签数据
                        Thread t = new Thread(new ParameterizedThreadStart(delBindThread));
                        t.Start(this.TabOrder.SelectedTabPage.Text);

                        #endregion
                    }
                }
                else
                {
                    MessageBox.Show("请挑选板件数据操作！", "提示");
                }
            }
        }
        //线程绑定数据
        private void delBindThread(object pageName)
        {
            for (int i = 0; i < TabOrder.TabPages.Count; i++)
            {
                //过滤已加载的页签及原始数据为空的页签
                if (TabOrder.TabPages[i].Text != pageName.ToString() && TabOrder.TabPages[i].Appearance.Header.BackColor != Color.BurlyWood)
                {
                    var gridControl = getGridControlByPages(TabOrder.TabPages[i]);
                    if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
                    {
                        try
                        {
                            //线程等待
                            DataTable tb = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(), ordId, gridControl.Name, this.Factory);
                            while (!this.IsHandleCreated)
                            {
                            }
                            this.BeginInvoke(new Action(() =>
                            {
                                if (tb != null && tb.Rows.Count == 0)
                                {
                                    XtraTabPage tabPage = gridControl.Parent as XtraTabPage;
                                    if (tabPage != null)
                                    {
                                        //操作后数据为空时
                                        var curList = pageTotal.Where(p => p.PageName == gridControl.Name);
                                        foreach (var cur in curList)
                                        {
                                            cur.TotalPrice = 0;
                                        }
                                        //整单汇总
                                        var totalList = pageTotal.Where(p => p.PageName == "整单汇总");
                                        foreach (var tl in totalList)
                                        {
                                            tl.TotalPrice = pageTotal.Where(p => p.PageName != tl.PageName && p.PlateCategory == tl.PlateCategory)
                                                    .Sum(p => p.TotalPrice);
                                        }
                                        tabPage.Appearance.Header.BackColor = Color.SandyBrown;
                                    }
                                }
                                else if (tb.Columns.Contains("PlateCategory") && tb.Columns.Contains("LegacyPrice"))
                                {
                                    DataTable tbPlateCategory = tb.DefaultView.ToTable(true, "PlateCategory");
                                    foreach (DataRow row in tbPlateCategory.Rows)
                                    {
                                        if (row[0] != null && row[0] != DBNull.Value && !string.IsNullOrEmpty(row[0].ToString()))
                                        {
                                            var curModel = pageTotal.Find(p => p.PageName == gridControl.Name && p.PlateCategory == row[0].ToString());
                                            if (curModel != null)
                                            {
                                                curModel.TotalPrice = 0;
                                                var value = tb.Compute("SUM(LegacyPrice)", "PlateCategory='" + row[0] + "' AND LegacyPrice > 0 ");
                                                if (value != null && value != DBNull.Value)
                                                {
                                                    curModel.TotalPrice = Convert.ToDecimal(value);
                                                }
                                            }
                                            //获取整单汇总 板件类别的信息
                                            var zpModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == curModel.PlateCategory);
                                            zpModel.TotalPrice = pageTotal.Where(p => p.PageName != zpModel.PageName && p.PlateCategory == zpModel.PlateCategory)
                                            .Sum(p => p.TotalPrice);
                                        }
                                    }
                                    var curTotalModel = pageTotal.Find(p => p.PageName == gridControl.Name && p.PlateCategory == "汇总");
                                    if (curTotalModel != null)
                                    {
                                        curTotalModel.TotalPrice = pageTotal.Where(p => p.PageName == curTotalModel.PageName && p.PlateCategory != "汇总").Sum(p => p.TotalPrice);
                                    }
                                    //获取整单汇总 汇总的信息
                                    var zhModel = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == "汇总");
                                    zhModel.TotalPrice = pageTotal.Where(p => p.PageName != zhModel.PageName && p.PlateCategory == "汇总")
                                    .Sum(p => p.TotalPrice);
                                }
                                gridControl.DataSource = tb;
                            }));
                        }
                        catch (Exception err)
                        {
                        }
                    }
                }
                if (i == TabOrder.TabPages.Count - 1)
                {
                    try
                    {
                        this.BeginInvoke(new Action(() =>
                        {
                            foreach (Control control in this.totalPanel.Controls)
                            {
                                var tBox = control as TextEdit;
                                if (tBox != null && tBox.Tag != null)
                                {
                                    tBox.Text = "0";
                                    var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == tBox.Tag.ToString());
                                    if (tEntity != null)
                                    {
                                        tBox.Text = tEntity.TotalPrice.ToString("0.##");
                                    }
                                }
                            }
                        }));
                    }
                    catch (Exception ex)
                    {
                    }
                }
            }
        }
        private void Save(XtraTabPage tabPage)
        {
            #region 获取汇总信息
            //List<YLOrdPagesTotalModel> totalList = new List<YLOrdPagesTotalModel>();
            //1、获取当前页签汇总信息
            foreach (Control control in this.curPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag != null && !string.IsNullOrEmpty(tBox.Text))
                {//
                    var entity = new YLOrdPagesTotalModel();
                    entity.PageName = tabPage.Text;
                    entity.PlateCategory = tBox.Tag.ToString();
                    entity.TotalPrice = Convert.ToDecimal(tBox.Text);
                    if (pageTotal.Contains(entity))
                    {
                        pageTotal.Remove(entity);
                    }
                    //若价格为0，则不添加
                    if (entity.TotalPrice > 0)
                    {
                        pageTotal.Add(entity);
                    }
                }
            }
            //2、获取整单汇总信息
            foreach (Control control in this.totalPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag != null && !string.IsNullOrEmpty(tBox.Text))
                {//
                    var entity = new YLOrdPagesTotalModel();
                    entity.PageName = "整单汇总";
                    entity.PlateCategory = tBox.Tag.ToString();
                    entity.TotalPrice = Convert.ToDecimal(tBox.Text);
                    //totalList.Add(entity);
                    if (pageTotal.Contains(entity))
                    {
                        pageTotal.Remove(entity);
                    }
                    //若价格为0，则不添加
                    if (entity.TotalPrice > 0)
                    {
                        pageTotal.Add(entity);
                    }
                }
            }
            #endregion

            #region 获取页签数据
            GridControl gridControl = getGridControlByPages(tabPage);
            if (gridControl != null && gridControl.Parent != null)
            {
                DataTable table = gridControl.DataSource as DataTable;
                if (table != null && table.Rows.Count > 0)
                {
                    #region 获取控件数据
                    DataRow[] drArr = table.Select("actions IN(5,6,8)"); //查询
                    foreach (DataRow row in drArr)
                    {
                        DataRow addRow = saveTable.NewRow();
                        foreach (DataColumn cm in row.Table.Columns)
                        {
                            if (saveTable.Columns.Contains(cm.ColumnName))
                            {
                                if (cm.ColumnName == "actions" && row[cm.ColumnName] != null)
                                {
                                    #region 转换操作类型
                                    if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.replace).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlReplace;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.add).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlAdd;
                                    }
                                    else if (row[cm.ColumnName].ToString() ==
                                             ((int)Common.ActionsType.update).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlUpdate;
                                    }
                                    #endregion
                                }
                                addRow[cm.ColumnName] = row[cm.ColumnName];
                            }
                        }
                        saveTable.Rows.Add(addRow);
                    }
                    #endregion
                }
            }
            #endregion

            #region 处理数据
            try
            {
                DataTable table = Common.CommonHelper.ConvertToTable<YLOrdPagesTotalModel>(pageTotal);
                Data.YLOrdersData.utlYLOrdEditingBatch(SqlConn, ordId, tabPage.Text, this.ordSource, saveTable, table);
                MessageBox.Show("保存成功！", "提示");
                if (this.saveTable.Rows.Count > 0)
                {
                    tabPage.Appearance.Header.BackColor = Color.Yellow;
                    gridControl.DataSource = Data.YLOrdersData.getStoredData(SqlConn, gridControl.Tag.ToString(), ordId, gridControl.Name, Factory);
                    //保存后清空
                    saveTable.Clear();
                }
                //if (totalList.Count > 0)
                //{
                //this.pageTotal = Data.YLOrdersData.getYLOrdPagesTotalData(SqlConn, ordId).ToList();
                //}
            }
            catch (Exception err)
            {
                //保存后清空
                saveTable.Clear();
                MessageBox.Show("保存失败！" + err.Message, "提示");
            }
            #endregion
        }

        /// <summary>
        /// 绑定窗体统计信息
        /// </summary>
        /// <param name="curPageName"></param>
        private void bindPanelControl(string curPageName)
        {
            //切换页签后，绑定整单统计信息
            foreach (Control control in this.totalPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag != null)
                {
                    tBox.Text = "0";
                    var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == tBox.Tag.ToString());
                    if (tEntity != null)
                    {
                        tBox.Text = tEntity.TotalPrice.ToString("0.##");
                    }
                }
            }
            //切换页签后，绑定当前统计信息
            foreach (Control control in this.curPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag != null)
                {
                    tBox.Text = "0";
                    var tEntity = pageTotal.Find(p => p.PageName == curPageName && p.PlateCategory == tBox.Tag.ToString());
                    if (tEntity != null)
                    {
                        tBox.Text = tEntity.TotalPrice.ToString("0.##");
                    }
                }
            }
        }

        private void setPanelControl(string PlateCategory, decimal value)
        {
            decimal price = 0;
            decimal sPrice = pageTotal.Where(p =>
                                p.PageName != this.TabOrder.SelectedTabPage.Text
                                && p.PageName != "整单汇总"
                                && p.PlateCategory == PlateCategory)
                         .Sum(p => p.TotalPrice);
            this.curPanel.Tag = "ValueChanged";
            //切换页签后，绑定整单统计信息
            foreach (Control control in this.totalPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag != null)
                {
                    if (tBox.Tag.ToString() == "汇总")
                    {
                        if (PlateCategory == "汇总")
                        {
                            var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == tBox.Tag.ToString());
                            if (tEntity != null)
                            {
                                tEntity.TotalPrice = sPrice + value;
                            }
                            tBox.Text = (sPrice + value).ToString("0.##");
                        }
                        else
                        {
                            price = pageTotal.Where(p =>
                                p.PageName == "整单汇总"
                               && p.PlateCategory != "汇总" && p.PlateCategory != PlateCategory)
                            .Sum(p => p.TotalPrice);
                            var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == tBox.Tag.ToString());
                            if (tEntity != null)
                            {
                                tEntity.TotalPrice = price + sPrice + value;
                            }
                            tBox.Text = (price + sPrice + value).ToString("0.##");
                        }
                    }
                    else if (tBox.Tag.ToString() == PlateCategory)
                    {
                        var tEntity = pageTotal.Find(p => p.PageName == "整单汇总" && p.PlateCategory == PlateCategory);
                        if (tEntity != null)
                        {
                            tEntity.TotalPrice = sPrice + value;
                        }
                        tBox.Text = (sPrice + value).ToString("0.##");
                    }
                }
            }
            //切换页签后，绑定当前统计信息
            foreach (Control control in this.curPanel.Controls)
            {
                var tBox = control as TextEdit;
                if (tBox != null && tBox.Tag.ToString() == "汇总" && PlateCategory != "汇总")
                {
                    //当前页签除该编辑板件类别外价格汇总
                    price = pageTotal.Where(p =>
                                       p.PageName == this.TabOrder.SelectedTabPage.Text &&
                                       p.PlateCategory != PlateCategory && p.PlateCategory != "汇总")
                                 .Sum(p => p.TotalPrice);
                    var tEntity = pageTotal.Find(p => p.PageName == this.TabOrder.SelectedTabPage.Text && p.PlateCategory == tBox.Tag.ToString());
                    if (tEntity != null)
                    {
                        tEntity.TotalPrice = price + value;
                    }
                    else
                    {
                        var entity = new YLOrdPagesTotalModel();
                        entity.PageName = this.TabOrder.SelectedTabPage.Text;
                        entity.PlateCategory = tBox.Tag.ToString();
                        entity.TotalPrice = price + value; ;
                        pageTotal.Add(entity);
                    }
                    tBox.Text = (price + value).ToString("0.##");
                }
            }
        }

    }
}
