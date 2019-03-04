namespace Tech2020.InSight.Oppein.Workers.Forms
{
    partial class mOrdersForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            DevExpress.XtraGrid.GridLevelNode gridLevelNode1 = new DevExpress.XtraGrid.GridLevelNode();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(mOrdersForm));
            this.tabControlOrder = new DevExpress.XtraTab.XtraTabControl();
            this.PageFirst = new DevExpress.XtraTab.XtraTabPage();
            this.gridControlOrder = new DevExpress.XtraGrid.GridControl();
            this.MenuItems = new System.Windows.Forms.ContextMenuStrip();
            this.MenuAdd = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem1 = new System.Windows.Forms.ToolStripSeparator();
            this.MenuDel = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripSeparator();
            this.toolStripMenuItem3 = new System.Windows.Forms.ToolStripSeparator();
            this.MenuRefresh = new System.Windows.Forms.ToolStripMenuItem();
            this.gridOrder = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.label4 = new System.Windows.Forms.Label();
            this.lblPONumber = new System.Windows.Forms.Label();
            this.lblOrdNo = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.tipOriginal = new DevExpress.Utils.ToolTipController();
            this.label2 = new System.Windows.Forms.Label();
            this.lblOrdDate = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.lblOtp = new System.Windows.Forms.Label();
            this.panel1 = new System.Windows.Forms.Panel();
            this.lblOrdBf = new System.Windows.Forms.Label();
            this.label23 = new System.Windows.Forms.Label();
            this.lblOrdKq = new System.Windows.Forms.Label();
            this.label27 = new System.Windows.Forms.Label();
            this.lblOrdHz = new System.Windows.Forms.Label();
            this.label29 = new System.Windows.Forms.Label();
            this.lblOrdSm = new System.Windows.Forms.Label();
            this.label31 = new System.Windows.Forms.Label();
            this.lblOrdGp = new System.Windows.Forms.Label();
            this.label35 = new System.Windows.Forms.Label();
            this.lblOrdGs = new System.Windows.Forms.Label();
            this.label39 = new System.Windows.Forms.Label();
            this.lblTM = new System.Windows.Forms.Label();
            this.label11 = new System.Windows.Forms.Label();
            this.lblBf = new System.Windows.Forms.Label();
            this.label15 = new System.Windows.Forms.Label();
            this.lblKq = new System.Windows.Forms.Label();
            this.lblKqName = new System.Windows.Forms.Label();
            this.lblHz = new System.Windows.Forms.Label();
            this.label16 = new System.Windows.Forms.Label();
            this.lblSm = new System.Windows.Forms.Label();
            this.label14 = new System.Windows.Forms.Label();
            this.lblLKM = new System.Windows.Forms.Label();
            this.label12 = new System.Windows.Forms.Label();
            this.lblGp = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.lblGs = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.btnSubmit = new System.Windows.Forms.Button();
            this.lblXS = new System.Windows.Forms.Label();
            this.label9 = new System.Windows.Forms.Label();
            this.lblOrdTM = new System.Windows.Forms.Label();
            this.label17 = new System.Windows.Forms.Label();
            this.lblOrdLKM = new System.Windows.Forms.Label();
            this.label19 = new System.Windows.Forms.Label();
            this.lblOrdXS = new System.Windows.Forms.Label();
            this.label21 = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.tabControlOrder)).BeginInit();
            this.tabControlOrder.SuspendLayout();
            this.PageFirst.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.gridControlOrder)).BeginInit();
            this.MenuItems.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.gridOrder)).BeginInit();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControlOrder
            // 
            this.tabControlOrder.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tabControlOrder.Location = new System.Drawing.Point(1, 59);
            this.tabControlOrder.MultiLine = DevExpress.Utils.DefaultBoolean.True;
            this.tabControlOrder.Name = "tabControlOrder";
            this.tabControlOrder.SelectedTabPage = this.PageFirst;
            this.tabControlOrder.Size = new System.Drawing.Size(1423, 626);
            this.tabControlOrder.TabIndex = 0;
            this.tabControlOrder.TabPages.AddRange(new DevExpress.XtraTab.XtraTabPage[] {
            this.PageFirst});
            // 
            // PageFirst
            // 
            this.PageFirst.Controls.Add(this.gridControlOrder);
            this.PageFirst.Name = "PageFirst";
            this.PageFirst.Size = new System.Drawing.Size(1416, 590);
            this.PageFirst.Text = "xtraTabPage1";
            // 
            // gridControlOrder
            // 
            this.gridControlOrder.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.gridControlOrder.ContextMenuStrip = this.MenuItems;
            gridLevelNode1.RelationName = "Level1";
            this.gridControlOrder.LevelTree.Nodes.AddRange(new DevExpress.XtraGrid.GridLevelNode[] {
            gridLevelNode1});
            this.gridControlOrder.Location = new System.Drawing.Point(-1, 0);
            this.gridControlOrder.MainView = this.gridOrder;
            this.gridControlOrder.Name = "gridControlOrder";
            this.gridControlOrder.Size = new System.Drawing.Size(1417, 596);
            this.gridControlOrder.TabIndex = 0;
            this.gridControlOrder.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.gridOrder});
            // 
            // MenuItems
            // 
            this.MenuItems.ImageScalingSize = new System.Drawing.Size(20, 20);
            this.MenuItems.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.MenuAdd,
            this.toolStripMenuItem1,
            this.MenuDel,
            this.toolStripMenuItem2,
            this.toolStripMenuItem3,
            this.MenuRefresh});
            this.MenuItems.Name = "contextMenuStrip1";
            this.MenuItems.Size = new System.Drawing.Size(113, 100);
            // 
            // MenuAdd
            // 
            this.MenuAdd.Image = ((System.Drawing.Image)(resources.GetObject("MenuAdd.Image")));
            this.MenuAdd.Name = "MenuAdd";
            this.MenuAdd.Size = new System.Drawing.Size(112, 26);
            this.MenuAdd.Text = "新增";
            this.MenuAdd.Click += new System.EventHandler(this.MenuAdd_Click);
            // 
            // toolStripMenuItem1
            // 
            this.toolStripMenuItem1.Name = "toolStripMenuItem1";
            this.toolStripMenuItem1.Size = new System.Drawing.Size(109, 6);
            // 
            // MenuDel
            // 
            this.MenuDel.Image = ((System.Drawing.Image)(resources.GetObject("MenuDel.Image")));
            this.MenuDel.Name = "MenuDel";
            this.MenuDel.Size = new System.Drawing.Size(112, 26);
            this.MenuDel.Text = "删除";
            this.MenuDel.Click += new System.EventHandler(this.MenuDel_Click);
            // 
            // toolStripMenuItem2
            // 
            this.toolStripMenuItem2.Name = "toolStripMenuItem2";
            this.toolStripMenuItem2.Size = new System.Drawing.Size(109, 6);
            // 
            // toolStripMenuItem3
            // 
            this.toolStripMenuItem3.Name = "toolStripMenuItem3";
            this.toolStripMenuItem3.Size = new System.Drawing.Size(109, 6);
            // 
            // MenuRefresh
            // 
            this.MenuRefresh.Image = ((System.Drawing.Image)(resources.GetObject("MenuRefresh.Image")));
            this.MenuRefresh.Name = "MenuRefresh";
            this.MenuRefresh.Size = new System.Drawing.Size(112, 26);
            this.MenuRefresh.Text = "刷新";
            this.MenuRefresh.Click += new System.EventHandler(this.MenuRefresh_Click);
            // 
            // gridOrder
            // 
            this.gridOrder.GridControl = this.gridControlOrder;
            this.gridOrder.Name = "gridOrder";
            this.gridOrder.OptionsView.ShowGroupPanel = false;
            this.gridOrder.RowHeight = 35;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label4.Location = new System.Drawing.Point(210, 20);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(68, 17);
            this.label4.TabIndex = 15;
            this.label4.Text = "合同号:";
            // 
            // lblPONumber
            // 
            this.lblPONumber.AutoSize = true;
            this.lblPONumber.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.lblPONumber.Location = new System.Drawing.Point(286, 20);
            this.lblPONumber.Name = "lblPONumber";
            this.lblPONumber.Size = new System.Drawing.Size(112, 17);
            this.lblPONumber.TabIndex = 16;
            this.lblPONumber.Text = "测试订单4856";
            // 
            // lblOrdNo
            // 
            this.lblOrdNo.AutoSize = true;
            this.lblOrdNo.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.lblOrdNo.Location = new System.Drawing.Point(98, 18);
            this.lblOrdNo.Name = "lblOrdNo";
            this.lblOrdNo.Size = new System.Drawing.Size(44, 17);
            this.lblOrdNo.TabIndex = 14;
            this.lblOrdNo.Text = "4856";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label1.Location = new System.Drawing.Point(26, 19);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(68, 17);
            this.label1.TabIndex = 13;
            this.label1.Text = "订单号:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label2.Location = new System.Drawing.Point(777, 20);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(85, 17);
            this.label2.TabIndex = 17;
            this.label2.Text = "订单日期:";
            // 
            // lblOrdDate
            // 
            this.lblOrdDate.AutoSize = true;
            this.lblOrdDate.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.lblOrdDate.Location = new System.Drawing.Point(869, 20);
            this.lblOrdDate.Name = "lblOrdDate";
            this.lblOrdDate.Size = new System.Drawing.Size(98, 17);
            this.lblOrdDate.TabIndex = 18;
            this.lblOrdDate.Text = "2018-01-02";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.label3.Location = new System.Drawing.Point(544, 20);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(85, 17);
            this.label3.TabIndex = 19;
            this.label3.Text = "订单类型:";
            // 
            // lblOtp
            // 
            this.lblOtp.AutoSize = true;
            this.lblOtp.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(134)));
            this.lblOtp.Location = new System.Drawing.Point(637, 20);
            this.lblOtp.Name = "lblOtp";
            this.lblOtp.Size = new System.Drawing.Size(42, 17);
            this.lblOtp.TabIndex = 20;
            this.lblOtp.Text = "测试";
            // 
            // panel1
            // 
            this.panel1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.panel1.Controls.Add(this.lblOrdXS);
            this.panel1.Controls.Add(this.label21);
            this.panel1.Controls.Add(this.lblOrdLKM);
            this.panel1.Controls.Add(this.label19);
            this.panel1.Controls.Add(this.lblOrdTM);
            this.panel1.Controls.Add(this.label17);
            this.panel1.Controls.Add(this.lblXS);
            this.panel1.Controls.Add(this.label9);
            this.panel1.Controls.Add(this.lblOrdBf);
            this.panel1.Controls.Add(this.label23);
            this.panel1.Controls.Add(this.lblOrdKq);
            this.panel1.Controls.Add(this.label27);
            this.panel1.Controls.Add(this.lblOrdHz);
            this.panel1.Controls.Add(this.label29);
            this.panel1.Controls.Add(this.lblOrdSm);
            this.panel1.Controls.Add(this.label31);
            this.panel1.Controls.Add(this.lblOrdGp);
            this.panel1.Controls.Add(this.label35);
            this.panel1.Controls.Add(this.lblOrdGs);
            this.panel1.Controls.Add(this.label39);
            this.panel1.Controls.Add(this.lblTM);
            this.panel1.Controls.Add(this.label11);
            this.panel1.Controls.Add(this.lblBf);
            this.panel1.Controls.Add(this.label15);
            this.panel1.Controls.Add(this.lblKq);
            this.panel1.Controls.Add(this.lblKqName);
            this.panel1.Controls.Add(this.lblHz);
            this.panel1.Controls.Add(this.label16);
            this.panel1.Controls.Add(this.lblSm);
            this.panel1.Controls.Add(this.label14);
            this.panel1.Controls.Add(this.lblLKM);
            this.panel1.Controls.Add(this.label12);
            this.panel1.Controls.Add(this.lblGp);
            this.panel1.Controls.Add(this.label10);
            this.panel1.Controls.Add(this.lblGs);
            this.panel1.Controls.Add(this.label7);
            this.panel1.Controls.Add(this.label6);
            this.panel1.Controls.Add(this.label5);
            this.panel1.Location = new System.Drawing.Point(1, 682);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(1417, 80);
            this.panel1.TabIndex = 21;
            // 
            // lblOrdBf
            // 
            this.lblOrdBf.AutoSize = true;
            this.lblOrdBf.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdBf.Location = new System.Drawing.Point(672, 48);
            this.lblOrdBf.Name = "lblOrdBf";
            this.lblOrdBf.Size = new System.Drawing.Size(18, 17);
            this.lblOrdBf.TabIndex = 56;
            this.lblOrdBf.Text = "0";
            // 
            // label23
            // 
            this.label23.AutoSize = true;
            this.label23.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label23.Location = new System.Drawing.Point(611, 48);
            this.label23.Name = "label23";
            this.label23.Size = new System.Drawing.Size(54, 17);
            this.label23.TabIndex = 55;
            this.label23.Text = "包覆:";
            // 
            // lblOrdKq
            // 
            this.lblOrdKq.AutoSize = true;
            this.lblOrdKq.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdKq.Location = new System.Drawing.Point(923, 47);
            this.lblOrdKq.Name = "lblOrdKq";
            this.lblOrdKq.Size = new System.Drawing.Size(18, 17);
            this.lblOrdKq.TabIndex = 52;
            this.lblOrdKq.Text = "0";
            // 
            // label27
            // 
            this.label27.AutoSize = true;
            this.label27.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label27.Location = new System.Drawing.Point(864, 47);
            this.label27.Name = "label27";
            this.label27.Size = new System.Drawing.Size(54, 17);
            this.label27.TabIndex = 51;
            this.label27.Text = "烤漆:";
            // 
            // lblOrdHz
            // 
            this.lblOrdHz.AutoSize = true;
            this.lblOrdHz.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdHz.Location = new System.Drawing.Point(1286, 47);
            this.lblOrdHz.Name = "lblOrdHz";
            this.lblOrdHz.Size = new System.Drawing.Size(18, 17);
            this.lblOrdHz.TabIndex = 50;
            this.lblOrdHz.Text = "0";
            // 
            // label29
            // 
            this.label29.AutoSize = true;
            this.label29.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label29.Location = new System.Drawing.Point(1226, 47);
            this.label29.Name = "label29";
            this.label29.Size = new System.Drawing.Size(54, 17);
            this.label29.TabIndex = 49;
            this.label29.Text = "汇总:";
            // 
            // lblOrdSm
            // 
            this.lblOrdSm.AutoSize = true;
            this.lblOrdSm.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdSm.Location = new System.Drawing.Point(796, 47);
            this.lblOrdSm.Name = "lblOrdSm";
            this.lblOrdSm.Size = new System.Drawing.Size(18, 17);
            this.lblOrdSm.TabIndex = 48;
            this.lblOrdSm.Text = "0";
            // 
            // label31
            // 
            this.label31.AutoSize = true;
            this.label31.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label31.Location = new System.Drawing.Point(737, 47);
            this.label31.Name = "label31";
            this.label31.Size = new System.Drawing.Size(54, 17);
            this.label31.TabIndex = 47;
            this.label31.Text = "实木:";
            // 
            // lblOrdGp
            // 
            this.lblOrdGp.AutoSize = true;
            this.lblOrdGp.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdGp.Location = new System.Drawing.Point(288, 47);
            this.lblOrdGp.Name = "lblOrdGp";
            this.lblOrdGp.Size = new System.Drawing.Size(18, 17);
            this.lblOrdGp.TabIndex = 44;
            this.lblOrdGp.Text = "0";
            // 
            // label35
            // 
            this.label35.AutoSize = true;
            this.label35.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label35.Location = new System.Drawing.Point(228, 47);
            this.label35.Name = "label35";
            this.label35.Size = new System.Drawing.Size(54, 17);
            this.label35.TabIndex = 43;
            this.label35.Text = "柜配:";
            // 
            // lblOrdGs
            // 
            this.lblOrdGs.AutoSize = true;
            this.lblOrdGs.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdGs.Location = new System.Drawing.Point(166, 48);
            this.lblOrdGs.Name = "lblOrdGs";
            this.lblOrdGs.Size = new System.Drawing.Size(18, 17);
            this.lblOrdGs.TabIndex = 40;
            this.lblOrdGs.Text = "0";
            // 
            // label39
            // 
            this.label39.AutoSize = true;
            this.label39.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label39.Location = new System.Drawing.Point(103, 48);
            this.label39.Name = "label39";
            this.label39.Size = new System.Drawing.Size(54, 17);
            this.label39.TabIndex = 39;
            this.label39.Text = "柜身:";
            // 
            // lblTM
            // 
            this.lblTM.AutoSize = true;
            this.lblTM.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblTM.Location = new System.Drawing.Point(1061, 7);
            this.lblTM.Name = "lblTM";
            this.lblTM.Size = new System.Drawing.Size(18, 17);
            this.lblTM.TabIndex = 38;
            this.lblTM.Text = "0";
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label11.Location = new System.Drawing.Point(994, 8);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(54, 17);
            this.label11.TabIndex = 37;
            this.label11.Text = "台面:";
            // 
            // lblBf
            // 
            this.lblBf.AutoSize = true;
            this.lblBf.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblBf.Location = new System.Drawing.Point(672, 8);
            this.lblBf.Name = "lblBf";
            this.lblBf.Size = new System.Drawing.Size(18, 17);
            this.lblBf.TabIndex = 36;
            this.lblBf.Text = "0";
            // 
            // label15
            // 
            this.label15.AutoSize = true;
            this.label15.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label15.Location = new System.Drawing.Point(611, 8);
            this.label15.Name = "label15";
            this.label15.Size = new System.Drawing.Size(54, 17);
            this.label15.TabIndex = 35;
            this.label15.Text = "包覆:";
            // 
            // lblKq
            // 
            this.lblKq.AutoSize = true;
            this.lblKq.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblKq.Location = new System.Drawing.Point(923, 8);
            this.lblKq.Name = "lblKq";
            this.lblKq.Size = new System.Drawing.Size(18, 17);
            this.lblKq.TabIndex = 32;
            this.lblKq.Text = "0";
            // 
            // lblKqName
            // 
            this.lblKqName.AutoSize = true;
            this.lblKqName.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblKqName.Location = new System.Drawing.Point(864, 8);
            this.lblKqName.Name = "lblKqName";
            this.lblKqName.Size = new System.Drawing.Size(54, 17);
            this.lblKqName.TabIndex = 31;
            this.lblKqName.Text = "烤漆:";
            // 
            // lblHz
            // 
            this.lblHz.AutoSize = true;
            this.lblHz.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblHz.Location = new System.Drawing.Point(1286, 8);
            this.lblHz.Name = "lblHz";
            this.lblHz.Size = new System.Drawing.Size(18, 17);
            this.lblHz.TabIndex = 18;
            this.lblHz.Text = "0";
            // 
            // label16
            // 
            this.label16.AutoSize = true;
            this.label16.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label16.Location = new System.Drawing.Point(1226, 8);
            this.label16.Name = "label16";
            this.label16.Size = new System.Drawing.Size(54, 17);
            this.label16.TabIndex = 17;
            this.label16.Text = "汇总:";
            // 
            // lblSm
            // 
            this.lblSm.AutoSize = true;
            this.lblSm.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblSm.Location = new System.Drawing.Point(797, 8);
            this.lblSm.Name = "lblSm";
            this.lblSm.Size = new System.Drawing.Size(18, 17);
            this.lblSm.TabIndex = 16;
            this.lblSm.Text = "0";
            // 
            // label14
            // 
            this.label14.AutoSize = true;
            this.label14.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label14.Location = new System.Drawing.Point(737, 8);
            this.label14.Name = "label14";
            this.label14.Size = new System.Drawing.Size(54, 17);
            this.label14.TabIndex = 15;
            this.label14.Text = "实木:";
            // 
            // lblLKM
            // 
            this.lblLKM.AutoSize = true;
            this.lblLKM.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblLKM.Location = new System.Drawing.Point(437, 8);
            this.lblLKM.Name = "lblLKM";
            this.lblLKM.Size = new System.Drawing.Size(18, 17);
            this.lblLKM.TabIndex = 14;
            this.lblLKM.Text = "0";
            // 
            // label12
            // 
            this.label12.AutoSize = true;
            this.label12.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label12.Location = new System.Drawing.Point(358, 8);
            this.label12.Name = "label12";
            this.label12.Size = new System.Drawing.Size(72, 17);
            this.label12.TabIndex = 13;
            this.label12.Text = "铝框门:";
            // 
            // lblGp
            // 
            this.lblGp.AutoSize = true;
            this.lblGp.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblGp.Location = new System.Drawing.Point(289, 8);
            this.lblGp.Name = "lblGp";
            this.lblGp.Size = new System.Drawing.Size(18, 17);
            this.lblGp.TabIndex = 12;
            this.lblGp.Text = "0";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label10.Location = new System.Drawing.Point(228, 8);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(54, 17);
            this.label10.TabIndex = 11;
            this.label10.Text = "柜配:";
            // 
            // lblGs
            // 
            this.lblGs.AutoSize = true;
            this.lblGs.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblGs.Location = new System.Drawing.Point(166, 8);
            this.lblGs.Name = "lblGs";
            this.lblGs.Size = new System.Drawing.Size(18, 17);
            this.lblGs.TabIndex = 7;
            this.lblGs.Text = "0";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label7.Location = new System.Drawing.Point(2, 47);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(90, 17);
            this.label7.TabIndex = 8;
            this.label7.Text = "整单汇总:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label6.Location = new System.Drawing.Point(3, 8);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(90, 17);
            this.label6.TabIndex = 7;
            this.label6.Text = "当前页签:";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label5.Location = new System.Drawing.Point(103, 8);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(54, 17);
            this.label5.TabIndex = 0;
            this.label5.Text = "柜身:";
            // 
            // btnSubmit
            // 
            this.btnSubmit.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSubmit.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnSubmit.Image = ((System.Drawing.Image)(resources.GetObject("btnSubmit.Image")));
            this.btnSubmit.Location = new System.Drawing.Point(1109, 9);
            this.btnSubmit.Name = "btnSubmit";
            this.btnSubmit.Size = new System.Drawing.Size(152, 40);
            this.btnSubmit.TabIndex = 22;
            this.btnSubmit.UseVisualStyleBackColor = true;
            this.btnSubmit.Click += new System.EventHandler(this.submit_Click);
            // 
            // lblXS
            // 
            this.lblXS.AutoSize = true;
            this.lblXS.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblXS.Location = new System.Drawing.Point(552, 8);
            this.lblXS.Name = "lblXS";
            this.lblXS.Size = new System.Drawing.Size(18, 17);
            this.lblXS.TabIndex = 60;
            this.lblXS.Text = "0";
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label9.Location = new System.Drawing.Point(491, 8);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(54, 17);
            this.label9.TabIndex = 59;
            this.label9.Text = "吸塑:";
            // 
            // lblOrdTM
            // 
            this.lblOrdTM.AutoSize = true;
            this.lblOrdTM.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdTM.Location = new System.Drawing.Point(1061, 48);
            this.lblOrdTM.Name = "lblOrdTM";
            this.lblOrdTM.Size = new System.Drawing.Size(18, 17);
            this.lblOrdTM.TabIndex = 62;
            this.lblOrdTM.Text = "0";
            // 
            // label17
            // 
            this.label17.AutoSize = true;
            this.label17.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label17.Location = new System.Drawing.Point(994, 47);
            this.label17.Name = "label17";
            this.label17.Size = new System.Drawing.Size(54, 17);
            this.label17.TabIndex = 61;
            this.label17.Text = "台面:";
            // 
            // lblOrdLKM
            // 
            this.lblOrdLKM.AutoSize = true;
            this.lblOrdLKM.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdLKM.Location = new System.Drawing.Point(435, 48);
            this.lblOrdLKM.Name = "lblOrdLKM";
            this.lblOrdLKM.Size = new System.Drawing.Size(18, 17);
            this.lblOrdLKM.TabIndex = 64;
            this.lblOrdLKM.Text = "0";
            // 
            // label19
            // 
            this.label19.AutoSize = true;
            this.label19.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label19.Location = new System.Drawing.Point(358, 48);
            this.label19.Name = "label19";
            this.label19.Size = new System.Drawing.Size(72, 17);
            this.label19.TabIndex = 63;
            this.label19.Text = "铝框门:";
            // 
            // lblOrdXS
            // 
            this.lblOrdXS.AutoSize = true;
            this.lblOrdXS.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.lblOrdXS.Location = new System.Drawing.Point(552, 47);
            this.lblOrdXS.Name = "lblOrdXS";
            this.lblOrdXS.Size = new System.Drawing.Size(18, 17);
            this.lblOrdXS.TabIndex = 66;
            this.lblOrdXS.Text = "0";
            // 
            // label21
            // 
            this.label21.AutoSize = true;
            this.label21.Font = new System.Drawing.Font("宋体", 10F, System.Drawing.FontStyle.Bold);
            this.label21.Location = new System.Drawing.Point(491, 47);
            this.label21.Name = "label21";
            this.label21.Size = new System.Drawing.Size(54, 17);
            this.label21.TabIndex = 65;
            this.label21.Text = "吸塑:";
            // 
            // mOrdersForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1422, 759);
            this.Controls.Add(this.btnSubmit);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.lblOtp);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.lblOrdDate);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.lblPONumber);
            this.Controls.Add(this.lblOrdNo);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.tabControlOrder);
            this.Name = "mOrdersForm";
            this.Text = "手工修改单界面";
            ((System.ComponentModel.ISupportInitialize)(this.tabControlOrder)).EndInit();
            this.tabControlOrder.ResumeLayout(false);
            this.PageFirst.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.gridControlOrder)).EndInit();
            this.MenuItems.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.gridOrder)).EndInit();
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private DevExpress.XtraTab.XtraTabControl tabControlOrder;
        private DevExpress.XtraTab.XtraTabPage PageFirst;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label lblPONumber;
        private System.Windows.Forms.Label lblOrdNo;
        private System.Windows.Forms.Label label1;
        private DevExpress.XtraGrid.GridControl gridControlOrder;
        private DevExpress.XtraGrid.Views.Grid.GridView gridOrder;
        private System.Windows.Forms.ContextMenuStrip MenuItems;
        private System.Windows.Forms.ToolStripMenuItem MenuAdd;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem MenuDel;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem2;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem3;
        private System.Windows.Forms.ToolStripMenuItem MenuRefresh;
        private DevExpress.Utils.ToolTipController tipOriginal;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label lblOrdDate;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label lblOtp;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.Label lblOrdBf;
        private System.Windows.Forms.Label label23;
        private System.Windows.Forms.Label lblOrdKq;
        private System.Windows.Forms.Label label27;
        private System.Windows.Forms.Label lblOrdHz;
        private System.Windows.Forms.Label label29;
        private System.Windows.Forms.Label lblOrdSm;
        private System.Windows.Forms.Label label31;
        private System.Windows.Forms.Label lblOrdGp;
        private System.Windows.Forms.Label label35;
        private System.Windows.Forms.Label lblOrdGs;
        private System.Windows.Forms.Label label39;
        private System.Windows.Forms.Label lblTM;
        private System.Windows.Forms.Label label11;
        private System.Windows.Forms.Label lblBf;
        private System.Windows.Forms.Label label15;
        private System.Windows.Forms.Label lblKq;
        private System.Windows.Forms.Label lblKqName;
        private System.Windows.Forms.Label lblHz;
        private System.Windows.Forms.Label label16;
        private System.Windows.Forms.Label lblSm;
        private System.Windows.Forms.Label label14;
        private System.Windows.Forms.Label lblLKM;
        private System.Windows.Forms.Label label12;
        private System.Windows.Forms.Label lblGp;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.Label lblGs;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Button btnSubmit;
        private System.Windows.Forms.Label lblXS;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label lblOrdXS;
        private System.Windows.Forms.Label label21;
        private System.Windows.Forms.Label lblOrdLKM;
        private System.Windows.Forms.Label label19;
        private System.Windows.Forms.Label lblOrdTM;
        private System.Windows.Forms.Label label17;
    }
}