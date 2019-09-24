using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics.Eventing.Reader;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Threading;
using DevExpress.Utils;
using DevExpress.XtraEditors;
using DevExpress.XtraEditors.Controls;
using DevExpress.XtraEditors.Repository;
using DevExpress.XtraGrid;
using DevExpress.XtraGrid.Columns;
using DevExpress.XtraGrid.Views.Base;
using DevExpress.XtraGrid.Views.Grid;
using DevExpress.XtraGrid.Views.Grid.ViewInfo;
using DevExpress.XtraTab;
using Tech2020.InSight.Oppein.Workers.Models;
using FontStyle = System.Drawing.FontStyle;
using Point = System.Drawing.Point;
using Size = System.Drawing.Size;

namespace Tech2020.InSight.Oppein.Workers.Forms
{
    public partial class mOrdersForm : System.Windows.Forms.Form
    {
        private int ordId { get; set; }
        private string ordSource { get; set; }
        private string otpCode { get; set; }
        private SqlConnection SqlConn { get; set; }
        private DataTable saveTable { get; set; }
        private List<Models.GridSummaryModel> sumGrid { get; set; }

        public mOrdersForm()
        {
            InitializeComponent();
        }

        public mOrdersForm(SqlConnection conn, int algId)
        {
            InitializeComponent();

            this.SqlConn = conn;
            var mOrdEntity = Data.ManualOrdersData.getManualOrderData(SqlConn, algId);
            if (mOrdEntity != null)
            {
                this.ordId = mOrdEntity.ordID;
                this.ordSource = mOrdEntity.ordSource;
                this.otpCode = mOrdEntity.otpCode;
                this.lblOrdNo.Text = mOrdEntity.ordOrderNo.ToString();
                this.lblPONumber.Text = mOrdEntity.ordPONumber;
                this.lblOtp.Text = mOrdEntity.otpDescription;
                this.lblOrdDate.Text = mOrdEntity.ordOrderDate;
                //初始化处理Table
                saveTable = Data.ManualOrdersData.getTypeColumns(SqlConn);
                var gridColumns = Data.ManualOrdersData.getGridColumnsData(SqlConn, this.ordId,mOrdEntity.otpCode,this.ordSource);
                var gridPages = gridColumns.GroupBy(p => new { p.pageName, p.pageSort, p.PageStoredProcedure,p.showPageColor })
                    .Select(p => new Models.GridPagesModel() { pageName = p.Key.pageName, pageSort = p.Key.pageSort, PageStoredProcedure = p.Key.PageStoredProcedure,showPageColor = p.Key.showPageColor}).ToList();
                if (gridPages.Count > 0)
                {
                    //绑定第一个页签及数据
                    PageFirst.Text = gridPages[0].pageName;
                    if (gridPages[0].showPageColor)
                    {
                        PageFirst.Appearance.Header.BackColor = Color.Yellow;
                    }
                    else
                    {
                        PageFirst.Appearance.Header.BackColor = Color.Green;
                    }
                    gridControlOrder.Tag= gridPages[0].PageStoredProcedure;
                    gridOrder.Appearance.HeaderPanel.TextOptions.HAlignment = HorzAlignment.Center;
                    gridOrder.OptionsView.ShowGroupPanel = false;
                    gridOrder.OptionsSelection.MultiSelect = true;
                    gridOrder.OptionsSelection.CheckBoxSelectorColumnWidth = 40;
                    gridOrder.OptionsSelection.MultiSelectMode = GridMultiSelectMode.CheckBoxRowSelect;
                    gridOrder.IndicatorWidth = 40;
                    gridOrder.CustomDrawRowIndicator += new RowIndicatorCustomDrawEventHandler(grid_CustomDrawRowIndicator);
                    gridOrder.MouseMove += new System.Windows.Forms.MouseEventHandler(grid_MouseMove);
                    gridOrder.CustomDrawCell += new RowCellCustomDrawEventHandler(grid_CustomDrawCell);
                    gridOrder.CellValueChanged+=new CellValueChangedEventHandler(grid_CellValueChanged);
                    gridOrder.CustomRowCellEdit+=new CustomRowCellEditEventHandler(gridOrder_CustomRowCellEdit);
                    gridOrder.ValidateRow+=new ValidateRowEventHandler(grid_ValidateRow);
                    gridOrder.Tag = gridPages[0].pageName;
                    //绑定第一个页签列
                    BindGridColumns(this.gridOrder, gridColumns, gridPages[0].pageName);
                    //绑定页签
                    BindTabPages(gridPages,gridColumns);
                    DataTable table= Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridPages[0].PageStoredProcedure, ordId);
                    //绑定数据
                    this.gridControlOrder.DataSource = table;
                    setSumGridValue(table, gridPages[0].pageName);
                    //赋值汇总
                    curFormValue(gridPages[0].pageName);
                    ////绑定提交按钮
                    //this.btnSubmit.Click+= new EventHandler(submit_Click);
                    ////tab选项卡切换事件
                    this.tabControlOrder.SelectedPageChanged+=new TabPageChangedEventHandler(tabControl_SelectedPageChanged);

                    if (table != null && table.Rows.Count == 0)
                    {
                        PageFirst.Appearance.Header.BackColor = Color.BurlyWood;
                    }

                    //后台加载其他页签数据
                    Thread bindThread = new Thread(new ThreadStart(BindThreadData));
                    bindThread.Start();
                }
            }
        }

        #region 自定义方法
        /// <summary>
        /// 绑定页签GridView列
        /// </summary>
        /// <param name="grid"></param>
        /// <param name="gridColumns"></param>
        /// <param name="pageName"></param>
        private void BindGridColumns(GridView grid, IList<Models.GridColumnModel> gridColumns, string pageName)
        {
            var pGridColumns = from p in gridColumns where p.pageName == pageName select p;
            foreach (var entity in pGridColumns)
            {
                #region 绑定列
                GridColumn cm = new GridColumn();
                cm.Name = entity.cmFieldName;
                cm.Caption = entity.cmFieldDesc;
                cm.FieldName = entity.cmFieldName;
                cm.VisibleIndex = entity.cmOrderSort;
                cm.Tag = entity.cmOriginalField;
                cm.UnboundType = Common.mOrderHelper.getGridColumnType(entity.cmFieldType);
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
                    cm.MinWidth= entity.cmFieldWidth;
                }
                if (entity.optType.ToLower() == "textex")
                {
                    RepositoryItemTextEdit textBox=new RepositoryItemTextEdit();
                    textBox.Validating += new CancelEventHandler(textBox_Validating);
                    cm.ColumnEdit = textBox;
                }
                if (entity.optType.ToLower() == "comboboxex" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    RepositoryItemComboBox combox = new RecentlyUsedItemsComboBox();
                    if (!String.IsNullOrEmpty(entity.cmBindField))
                    {
                        combox.Name = entity.cmBindField;
                    }
                    combox.Tag = entity.optStoredProcedure;
                    combox.ImmediatePopup = false;
                    combox.AutoComplete = false;//自动搜索筛选
                    combox.TextEditStyle = TextEditStyles.Standard;
                    combox.AllowDropDownWhenReadOnly = DefaultBoolean.True;
                    combox.EditValueChanging += new ChangingEventHandler(combox_EditValueChanging);
                    combox.Validating += new CancelEventHandler(combox_Validating);

                    DataTable table = Data.ManualOrdersData.getComboBoxData(SqlConn, entity.optStoredProcedure);
                    foreach (DataRow row in table.Rows)
                    {
                        combox.Items.Add(row[0].ToString());
                    }
                    cm.ColumnEdit = combox;
                }
                else if (entity.optType.ToLower() == "combobox" && !string.IsNullOrEmpty(entity.optStoredProcedure))
                {
                    #region 绑定ComboBox
                    DataTable tb = Data.ManualOrdersData.getStoredProcedureData(SqlConn, entity.optStoredProcedure);
                    if (tb != null && tb.Rows.Count > 0)
                    {
                        RepositoryItemMRUEdit ricbo = new RepositoryItemMRUEdit();
                        ricbo.AutoComplete = true;
                        ricbo.ImmediatePopup = true;
                        //MruEdit是否允许编辑
                        ricbo.TextEditStyle = TextEditStyles.DisableTextEditor;
                        //是否具有删除 绑定的数据源功能
                        ricbo.AllowRemoveMRUItems = false;
                        ricbo.DropDownRows = 12;
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
                    searchLookUp.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, entity.optStoredProcedure);
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
                if (tabPageList[i].showPageColor)
                {
                    xpage.Appearance.Header.BackColor = Color.Yellow;
                }
                else
                {
                    xpage.Appearance.Header.BackColor = Color.Green;
                }
                //xpage.Tag = tabPageList[i].PageStoredProcedure;
                xpage.Size = this.PageFirst.Size;
                GridControl gridControl = new GridControl();
                gridControl.Tag= tabPageList[i].PageStoredProcedure;
                GridView gridView = new GridView();
                gridView.Tag= tabPageList[i].pageName;
                gridView.GridControl = gridControl;
                gridView.OptionsView.ShowGroupPanel = false;
                gridView.Appearance.HeaderPanel.TextOptions.HAlignment=HorzAlignment.Center;
                gridView.RowHeight = 35;
                //gridView 事件及选项、序号设置
                gridView.OptionsView.ShowGroupPanel = false;
                gridView.OptionsSelection.MultiSelect = true;
                gridView.OptionsSelection.CheckBoxSelectorColumnWidth = 40;
                gridView.OptionsSelection.MultiSelectMode = GridMultiSelectMode.CheckBoxRowSelect;
                gridView.IndicatorWidth = 40;
                gridView.MouseMove += new System.Windows.Forms.MouseEventHandler(grid_MouseMove);
                gridView.CustomDrawCell += new RowCellCustomDrawEventHandler(grid_CustomDrawCell);
                gridView.CustomDrawRowIndicator += new RowIndicatorCustomDrawEventHandler(grid_CustomDrawRowIndicator);
                gridView.CellValueChanged += new CellValueChangedEventHandler(grid_CellValueChanged);
                gridView.ValidateRow += new ValidateRowEventHandler(grid_ValidateRow);
                gridView.CustomDrawEmptyForeground+=new CustomDrawEventHandler(grid_CustomDrawEmptyForeground);
                gridView.CustomRowCellEdit += new CustomRowCellEditEventHandler(gridOrder_CustomRowCellEdit);
                gridControl.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) | System.Windows.Forms.AnchorStyles.Left) | System.Windows.Forms.AnchorStyles.Right)));
                gridControl.ContextMenuStrip = this.MenuItems;
                gridControl.Location = this.gridControlOrder.Location;
                gridControl.Size = this.gridControlOrder.Size;
                gridControl.MainView = gridView;
                gridControl.ViewCollection.AddRange(new BaseView[] { gridView });

                BindGridColumns(gridView, gridColumns, tabPageList[i].pageName);
                xpage.Controls.Add(gridControl);//添加要增加的控件

                //System.Windows.Forms.Button submitBtn = new System.Windows.Forms.Button();
                //submitBtn.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
                //submitBtn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
                //submitBtn.Image = this.btnSubmit.Image;
                //submitBtn.Location = this.btnSubmit.Location;
                //submitBtn.Size = this.btnSubmit.Size;
                //submitBtn.TabIndex = 5;
                //submitBtn.UseVisualStyleBackColor = true;
                ////绑定提交按钮
                //submitBtn.Click += new EventHandler(submit_Click);

                //xpage.Controls.Add(submitBtn);//添加要增加的控件
                tabControlOrder.TabPages.Add(xpage);
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
            foreach (System.Windows.Forms.Control control in tabPage.Controls)
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
            foreach (System.Windows.Forms.Control control in tabPage.Controls)
            {
                gridControl = control as GridControl;
                if (gridControl != null)
                {
                    return gridControl.MainView as GridView;
                }
            }
            return null;
        }

        private void setSumGridValue(DataTable table,string pageName)
        {
            if (this.otpCode == "REPL")
            {
                DataView dv = new DataView(table);
                if (dv != null && dv.Count > 0 && dv.Table.Columns.Contains("PlateCategory") &&
                    dv.Table.Columns.Contains("LegacyPrice"))
                {
                    var sumEntity =Common.CommonHelper.GetEntities<GridSummaryModel>(dv.ToTable(false, "PlateCategory","LegacyPrice"));
                    var sumList = from entity in sumEntity
                                  where entity.PlateCategory != null
                                  group entity by new { category = entity.PlateCategory }
                                  into g
                                  select new GridSummaryModel()
                                  {
                                      pageName = pageName,
                                      PlateCategory = g.Key.category,
                                      LegacyPrice = g.Sum(n => n.LegacyPrice)
                                  };
                    if (this.sumGrid == null)
                    {
                        this.sumGrid = sumList.ToList();
                    }
                    else
                    {
                        this.sumGrid.RemoveAll(p => p.pageName == pageName);
                        this.sumGrid.AddRange(sumList.ToList());
                    }
                }
            }
        }

        private void curFormValue(string pageName)
        {
            if (this.otpCode == "REPL" && this.sumGrid != null)
            {
                //当前页签统计
                this.lblGs.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "柜身").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblGp.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "柜配").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblLKM.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "铝框门").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblXS.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "吸塑").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblBf.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "包覆").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblSm.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "实木").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblKq.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "烤漆").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblTM.Text = sumGrid.Where(p => p.pageName == pageName && p.PlateCategory == "台面").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblHz.Text = sumGrid.Where(p => p.pageName == pageName).Sum(p => p.LegacyPrice).ToString("0.##");
                //当前订单统计
                this.lblOrdGs.Text = sumGrid.Where(p => p.PlateCategory == "柜身").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdGp.Text = sumGrid.Where(p => p.PlateCategory == "柜配").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdLKM.Text = sumGrid.Where(p => p.PlateCategory == "铝框门").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdXS.Text = sumGrid.Where(p => p.PlateCategory == "吸塑").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdBf.Text = sumGrid.Where(p => p.PlateCategory == "包覆").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdSm.Text = sumGrid.Where(p => p.PlateCategory == "实木").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdKq.Text = sumGrid.Where(p => p.PlateCategory == "烤漆").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdTM.Text = sumGrid.Where(p => p.PlateCategory == "台面").Sum(p => p.LegacyPrice).ToString("0.##");
                this.lblOrdHz.Text = sumGrid.Sum(p => p.LegacyPrice).ToString("0.##");
            }
        }
        private void threadFormValue()
        {
            if (this.otpCode== "REPL" && this.sumGrid != null)
            {
                this.lblOrdGs.Invoke(new Action(() =>
                {
                    this.lblOrdGs.Text = sumGrid.Where(p => p.PlateCategory == "柜身").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdGp.Invoke(new Action(() =>
                {
                    this.lblOrdGp.Text = sumGrid.Where(p => p.PlateCategory == "柜配").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdLKM.Invoke(new Action(() =>
                {
                    this.lblOrdLKM.Text = sumGrid.Where(p => p.PlateCategory == "铝框门").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdXS.Invoke(new Action(() =>
                {
                    this.lblOrdXS.Text = sumGrid.Where(p => p.PlateCategory == "吸塑").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdBf.Invoke(new Action(() =>
                {
                    this.lblOrdBf.Text = sumGrid.Where(p => p.PlateCategory == "包覆").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdSm.Invoke(new Action(() =>
                {
                    this.lblOrdSm.Text = sumGrid.Where(p => p.PlateCategory == "实木").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdKq.Invoke(new Action(() =>
                {
                    this.lblOrdKq.Text = sumGrid.Where(p => p.PlateCategory == "烤漆").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdTM.Invoke(new Action(() =>
                {
                    this.lblOrdTM.Text = sumGrid.Where(p => p.PlateCategory == "台面").Sum(p => p.LegacyPrice).ToString("0.##");
                }));
                this.lblOrdHz.Invoke(new Action(() =>
                {
                    this.lblOrdHz.Text = sumGrid.Sum(p => p.LegacyPrice).ToString("0.##");
                }));
            }
        }

        //线程绑定数据
        private void BindThreadData()
        {
            for (int i = 1; i < tabControlOrder.TabPages.Count; i++)
            {
                var gridControl = getGridControlByPages(tabControlOrder.TabPages[i]);
                if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
                {
                    try
                    {
                        //线程等待
                        DataTable tb = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(),ordId);
                        while (!this.IsHandleCreated)
                        {
                        }
                        this.BeginInvoke(new Action(() =>
                        {
                            XtraTabPage tabPage = gridControl.Parent as XtraTabPage;
                            if (tabPage != null)
                            {
                                if (tb != null && tb.Rows.Count == 0)
                                {
                                    tabPage.Appearance.Header.BackColor = Color.BurlyWood;
                                }
                                else if (tb.Rows.Count > 0)
                                {
                                    setSumGridValue(tb, tabPage.Text);
                                }
                            }
                            gridControl.DataSource = tb;
                            //赋值汇总
                            threadFormValue();
                        }));
                    }
                    catch (Exception )
                    {
                    }
                }
            }
        }
        //保存方法
        private void Save(DataTable table, XtraTabPage tabPage,bool isShow)
        {
            if (table != null && table.Rows.Count > 0)
            {
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
                                if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.replace).ToString())
                                {
                                    row[cm.ColumnName] = (int)Common.ActionsType.sqlReplace;
                                }
                                else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.add).ToString())
                                {
                                    row[cm.ColumnName] = (int)Common.ActionsType.sqlAdd;
                                }
                                else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.update).ToString())
                                {
                                    row[cm.ColumnName] = (int)Common.ActionsType.sqlUpdate;
                                }
                            }
                            addRow[cm.ColumnName] = row[cm.ColumnName];
                        }
                    }
                    saveTable.Rows.Add(addRow);
                }
            }
            if (saveTable.Rows.Count > 0)
            {
                if (System.Windows.Forms.MessageBox.Show("是否保存当前页签操作数据", "信息提示",
                    System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Warning,
                    System.Windows.Forms.MessageBoxDefaultButton.Button2, 0, false) == System.Windows.Forms.DialogResult.Yes)
                {
                    try
                    {
                        Data.ManualOrdersData.utlMOrdEditingBatch(SqlConn, ordId, tabControlOrder.SelectedTabPage.Text,this.ordSource,
                            saveTable);
                        tabPage.Appearance.Header.BackColor = Color.Yellow;
                        System.Windows.Forms.MessageBox.Show("保存成功！", "提示");

                        GridControl gridControl = getGridControlByPages(tabPage);
                        if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
                        {
                            gridControl.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                        }
                        //保存后清空
                        saveTable.Clear();
                    }
                    catch (Exception err)
                    {
                        System.Windows.Forms.MessageBox.Show("保存失败！" + err.Message, "提示");
                    }
                }
                else
                {
                    //gridControl.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                    //saveTable.Clear();
                    //刷新
                    saveTable.Clear();
                }
            }
            else
            {
                if (isShow)
                {
                    System.Windows.Forms.MessageBox.Show("应用之前请操作该页签！", "提示");
                }
               
            }
        }

        private void Save(GridControl gridControl, bool showMsg)
        {
            if (gridControl != null && gridControl.Parent!=null)
            {
                DataTable table= gridControl.DataSource as DataTable;
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
                                    if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.replace).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlReplace;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.add).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlAdd;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.update).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlUpdate;
                                    }
                                }
                                addRow[cm.ColumnName] = row[cm.ColumnName];
                            }
                        }
                        saveTable.Rows.Add(addRow);
                    }
                    #endregion
                }
                if (saveTable.Rows.Count > 0)
                {
                    if (System.Windows.Forms.MessageBox.Show("是否保存当前页签操作数据", "信息提示",
                        System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Warning,
                        System.Windows.Forms.MessageBoxDefaultButton.Button2, 0, false) == System.Windows.Forms.DialogResult.Yes)
                    {
                        try
                        {
                            XtraTabPage tabPage = gridControl.Parent as XtraTabPage;
                            if (tabPage != null)
                            {
                                Data.ManualOrdersData.utlMOrdEditingBatch(SqlConn, ordId, tabPage.Text, this.ordSource, saveTable);
                                System.Windows.Forms.MessageBox.Show("保存成功！", "提示");
                                tabPage.Appearance.Header.BackColor = Color.Yellow;
                                gridControl.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                                //保存后清空
                                saveTable.Clear();
                            }
                            else
                            {
                               throw new Exception("找不到上级节点！");
                            }
                        }
                        catch (Exception err)
                        {
                            //保存后清空
                            saveTable.Clear();
                            System.Windows.Forms.MessageBox.Show("保存失败！" + err.Message, "提示");
                        }
                    }
                    else
                    {
                        gridControl.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                        //刷新
                        saveTable.Clear();
                    }
                }
                else
                {
                    if (showMsg)
                    {
                        System.Windows.Forms.MessageBox.Show("应用之前请操作该页签！", "提示");
                    }
                }
            }
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

        private ItemDimensionModel getItemDimension(string pageName, string edgeCode, int dimZ)
        {
            var resultEntity = new ItemDimensionModel();
            if (pageName == "普通柜身" || pageName == "普通功能件")
            {
                if (edgeCode == "1111")
                {
                    #region 代码为1111时
                    if (dimZ == 12 || dimZ == 18 || dimZ == 25)
                    {
                        resultEntity.dimX = 2;
                        resultEntity.dimY = 2;
                        resultEntity.dimZ = 0.02M;
                    }
                    else if (dimZ == 60)
                    {
                        resultEntity.dimX = 2.5M;
                        resultEntity.dimY = 2.5M;
                        resultEntity.dimZ = 0.02M;
                    }
                    else
                    {
                        resultEntity.dimX = 0;
                        resultEntity.dimY = 0;
                        resultEntity.dimZ = 0;
                    }
                    #endregion
                }
                else if (edgeCode == "1112")
                {
                    #region 代码为1112时
                    if (dimZ == 18 || dimZ == 25)
                    {
                        resultEntity.dimX = 2;
                        resultEntity.dimY = 2.5M;
                        resultEntity.dimZ = 0.02M;
                    }
                    else
                    {
                        resultEntity.dimX = 0;
                        resultEntity.dimY = 0;
                        resultEntity.dimZ = 0;
                    }
                    #endregion
                }
                else if (edgeCode == "2222")
                {
                    #region 代码为2222时
                    if (dimZ == 18 || dimZ == 25)
                    {
                        resultEntity.dimX = 3;
                        resultEntity.dimY = 3;
                        resultEntity.dimZ = 0.02M;
                    }
                    else if (dimZ == 36 || dimZ == 46)
                    {
                        resultEntity.dimX = 3.5M;
                        resultEntity.dimY = 3.5M;
                        resultEntity.dimZ = 0.02M;
                    }
                    else
                    {
                        resultEntity.dimX = 0;
                        resultEntity.dimY = 0;
                        resultEntity.dimZ = 0;
                    }
                    #endregion
                }
                else
                {
                    resultEntity.dimX = 0;
                    resultEntity.dimY = 0;
                    resultEntity.dimZ = 0;
                }
            }
            else if (pageName == "实木柜身" || pageName == "实木功能件")
            {
                if (edgeCode == "1111")
                {
                    resultEntity.dimX = 1.5M;
                    resultEntity.dimY = 1.5M;
                    resultEntity.dimZ = 0.02M;
                }
                else
                {
                    resultEntity.dimX = 0;
                    resultEntity.dimY = 0;
                    resultEntity.dimZ = 0;
                }
            }

            return resultEntity;
        }
        #endregion

        #region 单元格ComboBox控件事件
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
                           var bindValue=grid.GetFocusedRowCellValue(grid.Columns[comBox.Properties.Name]);
                            if (bindValue != null && bindValue != DBNull.Value)
                            {
                                comBox.Properties.Items.Clear();
                                DataTable table = Data.ManualOrdersData.getComboBoxData(SqlConn, comBox.Properties.Tag.ToString(), bindValue.ToString(), e.NewValue.ToString());
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
                    DataTable table = Data.ManualOrdersData.getComboBoxData(SqlConn, comBox.Properties.Tag.ToString(), e.NewValue.ToString());
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
            if (comBox != null && comBox.Properties != null && comBox.Parent != null )
            {
                GridControl gControl = comBox.Parent as GridControl;
                if (gControl != null)
                {
                    GridView grid = gControl.MainView as GridView;
                    if (grid != null)
                    {
                        if (string.IsNullOrEmpty(comBox.Text))
                        {
                            if (!((comBox.Properties.Name != null && !string.IsNullOrEmpty(comBox.Properties.Name))|| grid.FocusedColumn.Caption == "备注"))
                            {
                                e.Cancel = true; //验证
                            }
                            //if (grid.FocusedColumn.Caption != "备注" ||  !(comBox.Properties.Name != null && !string.IsNullOrEmpty(comBox.Properties.Name)))
                            //{
                            //    e.Cancel = true; //验证
                            //}
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
        private void textBox_Validating(object sender, CancelEventArgs e)
        {
            TextEdit textBox = sender as TextEdit;
            if (textBox != null && !string.IsNullOrEmpty(textBox.Text) && textBox.Parent != null)
            {
                try
                {
                    var s = Convert.ToDecimal(textBox.Text);
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

        #endregion

        private void searchLookUp_Validating(object sender, CancelEventArgs e)
        {
            SearchLookUpEdit searchLook = sender as SearchLookUpEdit;
            if (searchLook != null && searchLook.Properties!=null && searchLook.Parent!=null)
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
                            if (rows != null && rows.Length >0)
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
                                            gv.SetRowCellValue(index,gv.Columns[cm.ColumnName], row[cm.ColumnName]);
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

        #region 单元格Button控件单击事件
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
                    System.Windows.Forms.MessageBox.Show("找不到文件" + btn.Text, "信息提示");
                }
            }
            else
            {
                System.Windows.Forms.MessageBox.Show("无该FXM文件", "信息提示");
            }
        }
        #endregion

        #region 保存
        private void tabControl_SelectedPageChanged(object sender, TabPageChangedEventArgs e)
        {
            GridControl gridControl = getGridControlByPages(e.PrevPage);
            if (gridControl != null)
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
                                    if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.replace).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlReplace;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.add).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlAdd;
                                    }
                                    else if (row[cm.ColumnName].ToString() == ((int)Common.ActionsType.update).ToString())
                                    {
                                        row[cm.ColumnName] = (int)Common.ActionsType.sqlUpdate;
                                    }
                                }
                                addRow[cm.ColumnName] = row[cm.ColumnName];
                            }
                        }
                        saveTable.Rows.Add(addRow);
                    }
                    #endregion
                }
                if (saveTable.Rows.Count > 0)
                {
                    if (System.Windows.Forms.MessageBox.Show("是否保存当前页签操作数据", "信息提示",
                        System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Warning,
                        System.Windows.Forms.MessageBoxDefaultButton.Button2, 0, false) == System.Windows.Forms.DialogResult.Yes)
                    {
                        #region 数据保存
                        try
                        {
                            XtraTabPage tabPage = gridControl.Parent as XtraTabPage;
                            if (tabPage != null)
                            {
                                Data.ManualOrdersData.utlMOrdEditingBatch(SqlConn, ordId, tabPage.Text, this.ordSource, saveTable);
                                System.Windows.Forms.MessageBox.Show("保存成功！", "提示");
                                tabPage.Appearance.Header.BackColor = Color.Yellow;
                                DataTable tb = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                                gridControl.DataSource = tb;

                                setSumGridValue(tb, e.PrevPage.Text);
                                curFormValue(e.Page.Text);
                                //保存后清空
                                saveTable.Clear();
                            }
                            else
                            {
                                throw new Exception("找不到上级节点！");
                            }
                        }
                        catch (Exception err)
                        {
                            System.Windows.Forms.MessageBox.Show("保存失败！" + err.Message, "提示");

                            DataTable tb = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                            gridControl.DataSource = tb;
                            setSumGridValue(tb, e.PrevPage.Text);
                            curFormValue(e.Page.Text);
                            //保存后清空
                            saveTable.Clear();
                        }
                        #endregion
                    }
                    else
                    {
                        #region 上个页签数据不保存

                        DataTable tb = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                        gridControl.DataSource = tb;
                        setSumGridValue(tb, e.PrevPage.Text);
                        curFormValue(e.Page.Text);
                        //刷新
                        saveTable.Clear();
                        #endregion
                    }
                }
                else
                {
                    curFormValue(e.Page.Text);
                }
            }
        }
        private void submit_Click(object sender, EventArgs e)
        {
            GridControl gridControl = getGridControlByPages(tabControlOrder.SelectedTabPage);
            if (gridControl != null)
            {
                Save(gridControl,true);
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
        private void grid_MouseMove(object sender, System.Windows.Forms.MouseEventArgs e)
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
            if(e.Column.Visible)
            {
                GridView grid = sender as GridView;
                var actValue = grid.GetRowCellValue(e.RowHandle, grid.Columns["actions"]);
                if (actValue != null && actValue != DBNull.Value)
                {
                    if (actValue.ToString() == ((int)Common.ActionsType.add).ToString() || actValue.ToString() == ((int)Common.ActionsType.sqlAdd).ToString())
                    {
                        e.Appearance.BackColor = Color.BurlyWood;
                    }
                    else if (actValue.ToString() == ((int) Common.ActionsType.replace).ToString() ||
                             actValue.ToString() == ((int) Common.ActionsType.sqlReplace).ToString())
                    {
                        e.Appearance.BackColor = Color.Moccasin;
                    }
                    else if ((actValue.ToString() == ((int) Common.ActionsType.update).ToString() ||
                              actValue.ToString() == ((int) Common.ActionsType.sqlUpdate).ToString()) &&
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
                if (grid != null && grid.Tag != null && !string.IsNullOrEmpty(grid.Tag.ToString()))
                {
                    #region 有关联的存在下以项目
                    if (e.Column.FieldName == "dimCX" || e.Column.FieldName == "dimCY" || e.Column.FieldName == "dimCZ"
                            || e.Column.FieldName == "dimFX" || e.Column.FieldName == "dimFY" || e.Column.FieldName == "dimFZ"
                            || e.Column.FieldName == "edgeCode" )
                    {
                        #region 尺寸关联
                        if (grid.Columns["dimCX"] != null && grid.Columns["dimCY"] != null &&
                            grid.Columns["dimCZ"] != null && grid.Columns["dimFX"] != null &&
                            grid.Columns["dimFY"] != null && grid.Columns["dimFZ"] != null &&
                            grid.Columns["edgeCode"] != null)
                        {
                            var dimCX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCX"]);
                            var dimCY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCY"]);
                            var dimCZ = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimCZ"]);
                            var dimFX = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFX"]);
                            var dimFY = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFY"]);
                            var dimFZ = grid.GetRowCellValue(e.RowHandle, grid.Columns["dimFZ"]);
                            var edgeCode = grid.GetRowCellValue(e.RowHandle, grid.Columns["edgeCode"]);
                            if (e.Column.FieldName == "dimCX")
                            {
                                #region 尺寸关联，根据裁切尺寸，计算完工
                                if (dimCX != null && dimCX != DBNull.Value && dimFX != null && dimFX != DBNull.Value &&
                                    dimCZ != null && dimCZ != DBNull.Value && edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimX = Convert.ToDecimal(dimCX);
                                        decimal dDimFX = Convert.ToDecimal(dimFX);
                                        int iDimZ = Convert.ToInt16(dimCZ);
                                        var entity = getItemDimension(grid.Tag.ToString(), edgeCode.ToString(),
                                            iDimZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal jDimX = dDimX + entity.dimX;
                                            if (dDimFX != jDimX)
                                            {
                                                grid.Columns["dimFX"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFX"], jDimX);
                                            }
                                        }
                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), iDimZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal jDimX = dDimX + Convert.ToDecimal(tb.Rows[0][0]);
                                        //    if (dDimFX != jDimX)
                                        //    {
                                        //        grid.Columns["dimFX"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFX"], jDimX);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "dimCY")
                            {
                                #region 尺寸关联，根据裁切尺寸，计算完工
                                if (dimCY != null && dimCY != DBNull.Value && dimFY != null && dimFY != DBNull.Value &&
                                    dimCZ != null && dimCZ != DBNull.Value && edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimY = Convert.ToDecimal(dimCY);
                                        decimal dDimFY = Convert.ToDecimal(dimFY);
                                        int iDimZ = Convert.ToInt16(dimCZ);
                                        var entity = getItemDimension(grid.Tag.ToString(), edgeCode.ToString(), iDimZ);
                                        if (entity != null && entity.dimY > -1)
                                        {
                                            decimal jDimY = dDimY + entity.dimY;
                                            if (dDimFY != jDimY)
                                            {
                                                grid.Columns["dimFY"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFY"], jDimY);
                                            }
                                        }

                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), iDimZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal jDimY = dDimY + Convert.ToDecimal(tb.Rows[0][1]);
                                        //    if (dDimFY != jDimY)
                                        //    {
                                        //        grid.Columns["dimFY"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFY"], jDimY);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "dimCZ")
                            {
                                #region 尺寸关联，根据裁切尺寸，计算完工
                                if (dimCX != null && dimCX != DBNull.Value && dimCY != null && dimCY != DBNull.Value &&
                                    dimCZ != null && dimCZ != DBNull.Value && dimFX != null && dimFX != DBNull.Value &&
                                    dimFY != null && dimFY != DBNull.Value && dimFZ != null && dimFZ != DBNull.Value &&
                                    edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimX = Convert.ToDecimal(dimCX);
                                        decimal dDimY = Convert.ToDecimal(dimCY);
                                        decimal dDimZ = Convert.ToDecimal(dimCZ);
                                        int iDimZ = Convert.ToInt16(dimCZ);
                                        decimal dDimFX = Convert.ToDecimal(dimFX);
                                        decimal dDimFY = Convert.ToDecimal(dimFY);
                                        decimal dDimFZ = Convert.ToDecimal(dimFZ);

                                        var entity = getItemDimension(grid.Tag.ToString(), edgeCode.ToString(), iDimZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal tDimX = dDimX + entity.dimX;
                                            if (dDimFX != tDimX)
                                            {
                                                grid.Columns["dimFX"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFX"], tDimX);
                                            }
                                            decimal tDimY = dDimY + entity.dimY;
                                            if (dDimFY != tDimY)
                                            {
                                                grid.Columns["dimFY"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFY"], tDimY);
                                            }
                                            //当裁切厚为整数，则取整数
                                            if (iDimZ == dDimZ)
                                            {
                                                if (dDimFZ != dDimZ)
                                                {
                                                    grid.Columns["dimFZ"].OptionsColumn.AllowEdit = false;
                                                    grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFZ"], dDimZ);
                                                }
                                            }
                                            else
                                            {
                                                decimal tDimZ = dDimZ + entity.dimZ;
                                                if (dDimFZ != tDimZ)
                                                {
                                                    grid.Columns["dimFZ"].OptionsColumn.AllowEdit = false;
                                                    grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFZ"], tDimZ);
                                                }
                                            }
                                        }

                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), dDimZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal tDimX = dDimX + Convert.ToDecimal(tb.Rows[0][0]);
                                        //    if (dDimFX != tDimX)
                                        //    {
                                        //        grid.Columns["dimFX"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFX"], tDimX);
                                        //    }
                                        //    decimal tDimY = dDimY + Convert.ToDecimal(tb.Rows[0][1]);
                                        //    if (dDimFY != tDimY)
                                        //    {
                                        //        grid.Columns["dimFY"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFY"], tDimY);
                                        //    }
                                        //    decimal tDimZ = dDimZ + Convert.ToDecimal(tb.Rows[0][2]);
                                        //    if (dDimFZ != tDimZ)
                                        //    {
                                        //        grid.Columns["dimFZ"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimFZ"], tDimZ);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "dimFX")
                            {
                                #region 尺寸关联，根据完工尺寸，计算裁切
                                if (dimCX != null && dimCX != DBNull.Value && dimFX != null && dimFX != DBNull.Value &&
                                    dimFZ != null && dimFZ != DBNull.Value && edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimCX = Convert.ToDecimal(dimCX);
                                        decimal dDimFX = Convert.ToDecimal(dimFX);
                                        int dDimFZ = Convert.ToInt16(dimFZ);
                                        var entity = getItemDimension(grid.Tag.ToString(),
                                            edgeCode.ToString(), dDimFZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal tDimX = dDimFX - entity.dimX;
                                            if (dDimCX != tDimX)
                                            {
                                                grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                            }
                                        }
                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), dDimFZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal tDimX = dDimFX - Convert.ToDecimal(tb.Rows[0][0]);
                                        //    if (dDimCX != tDimX)
                                        //    {
                                        //        grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "dimFY")
                            {
                                #region 尺寸关联，根据完工尺寸，计算裁切
                                if (dimCY != null && dimCY != DBNull.Value && dimFY != null && dimFY != DBNull.Value &&
                                    dimFZ != null && dimFZ != DBNull.Value && edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimCY = Convert.ToDecimal(dimCY);
                                        decimal dDimFY = Convert.ToDecimal(dimFY);
                                        int dDimFZ = Convert.ToInt16(dimFZ);
                                        var entity = getItemDimension(grid.Tag.ToString(),
                                            edgeCode.ToString(), dDimFZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal tDimY = dDimFY - entity.dimY;
                                            if (dDimCY != tDimY)
                                            {
                                                grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                            }
                                        }

                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), dDimFZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal tDimY = dDimFY - Convert.ToDecimal(tb.Rows[0][1]);
                                        //    if (dDimCY != tDimY)
                                        //    {
                                        //        grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "dimFZ")
                            {
                                #region 尺寸关联，根据完工尺寸，计算裁切
                                if (dimCX != null && dimCX != DBNull.Value && dimCY != null && dimCY != DBNull.Value &&
                                    dimCZ != null && dimCZ != DBNull.Value && dimFX != null && dimFX != DBNull.Value &&
                                    dimFY != null && dimFY != DBNull.Value && dimFZ != null && dimFZ != DBNull.Value &&
                                    edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimCX = Convert.ToDecimal(dimCX);
                                        decimal dDimCY = Convert.ToDecimal(dimCY);
                                        decimal dDimCZ = Convert.ToDecimal(dimCZ);
                                        decimal dDimFX = Convert.ToDecimal(dimFX);
                                        decimal dDimFY = Convert.ToDecimal(dimFY);
                                        int dDimFZ = Convert.ToInt16(dimFZ);
                                        var entity = getItemDimension(grid.Tag.ToString(),
                                            edgeCode.ToString(), dDimFZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal tDimX = dDimFX - entity.dimX;
                                            if (dDimCX != tDimX)
                                            {
                                                grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                            }
                                            decimal tDimY = dDimFY - entity.dimY;
                                            if (dDimCY != tDimY)
                                            {
                                                grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                            }
                                            decimal tDimZ = dDimFZ - entity.dimZ;
                                            if (dDimCZ != tDimZ)
                                            {
                                                grid.Columns["dimCZ"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCZ"], tDimZ);
                                            }
                                        }

                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), dDimFZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal tDimX = dDimFX - Convert.ToDecimal(tb.Rows[0][0]);
                                        //    if (dDimCX != tDimX)
                                        //    {
                                        //        grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                        //    }
                                        //    decimal tDimY = dDimFY - Convert.ToDecimal(tb.Rows[0][1]);
                                        //    if (dDimCY != tDimY)
                                        //    {
                                        //        grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                        //    }
                                        //    decimal tDimZ = dDimFZ - Convert.ToDecimal(tb.Rows[0][2]);
                                        //    if (dDimCZ != tDimZ)
                                        //    {
                                        //        grid.Columns["dimCZ"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCZ"], tDimZ);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                            else if (e.Column.FieldName == "edgeCode")
                            {
                                #region 尺寸关联，根据完工尺寸，计算裁切
                                if (dimCX != null && dimCX != DBNull.Value && dimCY != null && dimCY != DBNull.Value &&
                                    dimFX != null && dimFX != DBNull.Value &&
                                    dimFY != null && dimFY != DBNull.Value && dimFZ != null && dimFZ != DBNull.Value &&
                                    edgeCode != null && edgeCode != DBNull.Value)
                                {
                                    try
                                    {
                                        decimal dDimCX = Convert.ToDecimal(dimCX);
                                        decimal dDimCY = Convert.ToDecimal(dimCY);
                                        decimal dDimFX = Convert.ToDecimal(dimFX);
                                        decimal dDimFY = Convert.ToDecimal(dimFY);
                                        int dDimFZ = Convert.ToInt16(dimFZ);
                                        var entity = getItemDimension(grid.Tag.ToString(),
                                            edgeCode.ToString(), dDimFZ);
                                        if (entity != null && entity.dimX > -1)
                                        {
                                            decimal tDimX = dDimFX - entity.dimX;
                                            if (dDimCX != tDimX)
                                            {
                                                grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                            }
                                            decimal tDimY = dDimFY - entity.dimY;
                                            if (dDimCY != tDimY)
                                            {
                                                grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                                grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                            }
                                        }

                                        //DataTable tb = Data.YLOrdersData.getItemDimensions(SqlConn, grid.Tag.ToString(),
                                        //    edgeCode.ToString(), dDimFZ);
                                        //if (tb != null && tb.Rows.Count == 1)
                                        //{
                                        //    decimal tDimX = dDimFX - Convert.ToDecimal(tb.Rows[0][0]);
                                        //    if (dDimCX != tDimX)
                                        //    {
                                        //        grid.Columns["dimCX"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCX"], tDimX);
                                        //    }
                                        //    decimal tDimY = dDimFY - Convert.ToDecimal(tb.Rows[0][1]);
                                        //    if (dDimCY != tDimY)
                                        //    {
                                        //        grid.Columns["dimCY"].OptionsColumn.AllowEdit = false;
                                        //        grid.SetRowCellValue(e.RowHandle, grid.Columns["dimCY"], tDimY);
                                        //    }
                                        //}
                                    }
                                    catch (Exception ex)
                                    {
                                        throw new Exception(ex.Message);
                                    }
                                }
                                #endregion
                            }
                        }
                        #endregion

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
                                    grid.Columns["Area"].OptionsColumn.AllowEdit = false;
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
                                    grid.Columns["cArea"].OptionsColumn.AllowEdit = false;
                                    grid.SetRowCellValue(e.RowHandle, grid.Columns["cArea"], areaValue);
                                }
                            }
                        }
                        #endregion
                    }
                    #endregion

                    #region 操作状态
                    var actValue = grid.GetRowCellValue(e.RowHandle, grid.Columns["actions"]);
                    if (actValue != null)
                    {
                        if (actValue == DBNull.Value ||
                            actValue.ToString() == ((int)Common.ActionsType.sqlUpdate).ToString()
                            || actValue.ToString() == ((int)Common.ActionsType.sqlAdd).ToString()
                            || actValue.ToString() == ((int)Common.ActionsType.sqlReplace).ToString())
                        {
                            grid.SetRowCellValue(e.RowHandle, grid.Columns["actions"], (int)Common.ActionsType.update);
                        }
                    }
                    #endregion
                    
                }
            }
            else
            {
                if (e.Column.FieldName == "dimCX" || e.Column.FieldName == "dimCY" || e.Column.FieldName == "dimCZ"
                    || e.Column.FieldName == "dimFX" || e.Column.FieldName == "dimFY" || e.Column.FieldName == "dimFZ"
                    || e.Column.FieldName == "Area" || e.Column.FieldName == "cArea" || e.Column.FieldName == "LegacyPrice")
                {
                    e.Column.OptionsColumn.AllowEdit = true;
                }
            }
        }

        RepositoryItemButtonEdit _disItemBtn;
        private void gridOrder_CustomRowCellEdit(object sender,CustomRowCellEditEventArgs e)
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
            if (grid != null)
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
                if (this.lblOtp.Text=="遗留单" && grid.Tag != null && !string.IsNullOrEmpty(grid.Tag.ToString()) && grid.DataSource !=null)
                {
                    var pageName = grid.Tag.ToString();
                    var dv = grid.DataSource as DataView;
                    if (dv != null && dv.Count>0 && dv.Table.Columns.Contains("PlateCategory") && dv.Table.Columns.Contains("LegacyPrice"))
                    {
                        var sumEntity =Common.CommonHelper.GetEntities<GridSummaryModel>(dv.ToTable(false, "PlateCategory", "LegacyPrice"));
                        var sumList=from entity in sumEntity where entity.PlateCategory !=null group entity by new { category=entity.PlateCategory} into g
                                    select new GridSummaryModel() {pageName = pageName,
                                        PlateCategory = g.Key.category,
                                        LegacyPrice = g.Sum(n => n.LegacyPrice)
                                    };
                        if (this.sumGrid == null)
                        {
                            this.sumGrid = sumList.ToList();
                        }
                        else
                        {
                            this.sumGrid.RemoveAll(p => p.pageName == pageName);
                            this.sumGrid.AddRange(sumList.ToList());
                        }
                        curFormValue(pageName);
                    }
                }
            }
        }
        #endregion

        #region 右键菜单事件
        private void MenuAdd_Click(object sender, EventArgs e)
        {
            GridView gv = getGridViewByPages(tabControlOrder.SelectedTabPage);
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
                    if (this.ordSource=="CAD" ||tabControlOrder.SelectedTabPage.Text == "普通五金" || tabControlOrder.SelectedTabPage.Text == "实木五金" || tabControlOrder.SelectedTabPage.Text == "CY单")
                    {
                        gv.AddNewRow();
                        gv.SetFocusedRowCellValue(gv.Columns["actions"], (int)Common.ActionsType.add);
                    }
                    else
                    {
                        System.Windows.Forms.MessageBox.Show("请选择要新增的项复制！", "提示");
                    }
                }
            }
        }
        private void MenuDel_Click(object sender, EventArgs e)
        {
            GridView gv = getGridViewByPages(tabControlOrder.SelectedTabPage);
            if (gv != null)
            {
                if (gv.GetSelectedRows().Count() > 0)
                {
                    if (System.Windows.Forms.MessageBox.Show("你确定要删除选中的记录吗？", "删除提示",
                        System.Windows.Forms.MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Warning,
                            System.Windows.Forms.MessageBoxDefaultButton.Button2, 0, false) == System.Windows.Forms.DialogResult.Yes)
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
                    System.Windows.Forms.MessageBox.Show("请选择要删除的项！", "提示");
                }
            }
        }
        private void MenuRefresh_Click(object sender, EventArgs e)
        {
            GridControl gridControl = getGridControlByPages(tabControlOrder.SelectedTabPage);
            if (gridControl != null && gridControl.Tag != null && gridControl.Tag != DBNull.Value)
            {
                try
                {
                    gridControl.DataSource = Data.ManualOrdersData.getStoredProcedureData(SqlConn, gridControl.Tag.ToString(), ordId);
                }
                catch (Exception err)
                {
                    System.Windows.Forms.MessageBox.Show("获取数据失败！" + err.Message, "信息提示");
                }
               
                saveTable.Clear();
            }
        }
        #endregion
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
    }
}
