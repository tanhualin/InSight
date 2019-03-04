namespace Tech2020.InSight.Oppein.YLWorkers.Forms
{
    partial class YLOrderForm
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
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(YLOrderForm));
            this.PanelOrderHeader = new DevExpress.XtraEditors.PanelControl();
            this.btnDelAll = new DevExpress.XtraEditors.SimpleButton();
            this.lblOrdDate = new DevExpress.XtraEditors.LabelControl();
            this.labelControl8 = new DevExpress.XtraEditors.LabelControl();
            this.lblOtp = new DevExpress.XtraEditors.LabelControl();
            this.labelControl6 = new DevExpress.XtraEditors.LabelControl();
            this.lblPONumber = new DevExpress.XtraEditors.LabelControl();
            this.labelControl4 = new DevExpress.XtraEditors.LabelControl();
            this.lblOrdNo = new DevExpress.XtraEditors.LabelControl();
            this.btnSubmit = new DevExpress.XtraEditors.SimpleButton();
            this.labelControl1 = new DevExpress.XtraEditors.LabelControl();
            this.TabOrder = new DevExpress.XtraTab.XtraTabControl();
            this.PageOrder = new DevExpress.XtraTab.XtraTabPage();
            this.GridOrder = new DevExpress.XtraGrid.GridControl();
            this.cMenuItems = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.MenuAdd = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem1 = new System.Windows.Forms.ToolStripSeparator();
            this.MenuDel = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem2 = new System.Windows.Forms.ToolStripSeparator();
            this.MenuRefresh = new System.Windows.Forms.ToolStripMenuItem();
            this.toolStripMenuItem4 = new System.Windows.Forms.ToolStripSeparator();
            this.ViewOrder = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.PanelOrderTotal = new DevExpress.XtraEditors.PanelControl();
            this.totalPanel = new System.Windows.Forms.FlowLayoutPanel();
            this.curPanel = new System.Windows.Forms.FlowLayoutPanel();
            this.labelControl28 = new DevExpress.XtraEditors.LabelControl();
            this.labelControl10 = new DevExpress.XtraEditors.LabelControl();
            this.tipOriginal = new DevExpress.Utils.ToolTipController(this.components);
            ((System.ComponentModel.ISupportInitialize)(this.PanelOrderHeader)).BeginInit();
            this.PanelOrderHeader.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.TabOrder)).BeginInit();
            this.TabOrder.SuspendLayout();
            this.PageOrder.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.GridOrder)).BeginInit();
            this.cMenuItems.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.ViewOrder)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.PanelOrderTotal)).BeginInit();
            this.PanelOrderTotal.SuspendLayout();
            this.SuspendLayout();
            // 
            // PanelOrderHeader
            // 
            this.PanelOrderHeader.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.PanelOrderHeader.Controls.Add(this.btnDelAll);
            this.PanelOrderHeader.Controls.Add(this.lblOrdDate);
            this.PanelOrderHeader.Controls.Add(this.labelControl8);
            this.PanelOrderHeader.Controls.Add(this.lblOtp);
            this.PanelOrderHeader.Controls.Add(this.labelControl6);
            this.PanelOrderHeader.Controls.Add(this.lblPONumber);
            this.PanelOrderHeader.Controls.Add(this.labelControl4);
            this.PanelOrderHeader.Controls.Add(this.lblOrdNo);
            this.PanelOrderHeader.Controls.Add(this.btnSubmit);
            this.PanelOrderHeader.Controls.Add(this.labelControl1);
            this.PanelOrderHeader.Location = new System.Drawing.Point(3, 3);
            this.PanelOrderHeader.Name = "PanelOrderHeader";
            this.PanelOrderHeader.Size = new System.Drawing.Size(1416, 59);
            this.PanelOrderHeader.TabIndex = 1;
            // 
            // btnDelAll
            // 
            this.btnDelAll.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnDelAll.Appearance.Font = new System.Drawing.Font("Tahoma", 12F, System.Drawing.FontStyle.Bold);
            this.btnDelAll.Appearance.Options.UseFont = true;
            this.btnDelAll.Location = new System.Drawing.Point(1019, 6);
            this.btnDelAll.Name = "btnDelAll";
            this.btnDelAll.Size = new System.Drawing.Size(120, 45);
            this.btnDelAll.TabIndex = 9;
            this.btnDelAll.Text = "批量删除";
            this.btnDelAll.Click += new System.EventHandler(this.btnDelAll_Click);
            // 
            // lblOrdDate
            // 
            this.lblOrdDate.Location = new System.Drawing.Point(833, 20);
            this.lblOrdDate.Name = "lblOrdDate";
            this.lblOrdDate.Size = new System.Drawing.Size(74, 18);
            this.lblOrdDate.TabIndex = 8;
            this.lblOrdDate.Text = "2018-12-10";
            // 
            // labelControl8
            // 
            this.labelControl8.Location = new System.Drawing.Point(762, 20);
            this.labelControl8.Name = "labelControl8";
            this.labelControl8.Size = new System.Drawing.Size(65, 18);
            this.labelControl8.TabIndex = 7;
            this.labelControl8.Text = "订单日期:";
            // 
            // lblOtp
            // 
            this.lblOtp.Location = new System.Drawing.Point(619, 20);
            this.lblOtp.Name = "lblOtp";
            this.lblOtp.Size = new System.Drawing.Size(45, 18);
            this.lblOtp.TabIndex = 6;
            this.lblOtp.Text = "遗留单";
            // 
            // labelControl6
            // 
            this.labelControl6.Location = new System.Drawing.Point(548, 20);
            this.labelControl6.Name = "labelControl6";
            this.labelControl6.Size = new System.Drawing.Size(65, 18);
            this.labelControl6.TabIndex = 5;
            this.labelControl6.Text = "订单类型:";
            // 
            // lblPONumber
            // 
            this.lblPONumber.Location = new System.Drawing.Point(293, 20);
            this.lblPONumber.Name = "lblPONumber";
            this.lblPONumber.Size = new System.Drawing.Size(129, 18);
            this.lblPONumber.TabIndex = 4;
            this.lblPONumber.Text = "YL20187452264652";
            // 
            // labelControl4
            // 
            this.labelControl4.Location = new System.Drawing.Point(236, 20);
            this.labelControl4.Name = "labelControl4";
            this.labelControl4.Size = new System.Drawing.Size(50, 18);
            this.labelControl4.TabIndex = 3;
            this.labelControl4.Text = "合同号:";
            // 
            // lblOrdNo
            // 
            this.lblOrdNo.Location = new System.Drawing.Point(84, 20);
            this.lblOrdNo.Name = "lblOrdNo";
            this.lblOrdNo.Size = new System.Drawing.Size(64, 18);
            this.lblOrdNo.TabIndex = 2;
            this.lblOrdNo.Text = "65777168";
            // 
            // btnSubmit
            // 
            this.btnSubmit.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSubmit.Appearance.Font = new System.Drawing.Font("Tahoma", 12F, System.Drawing.FontStyle.Bold);
            this.btnSubmit.Appearance.Options.UseFont = true;
            this.btnSubmit.Location = new System.Drawing.Point(1200, 6);
            this.btnSubmit.Name = "btnSubmit";
            this.btnSubmit.Size = new System.Drawing.Size(100, 45);
            this.btnSubmit.TabIndex = 1;
            this.btnSubmit.Text = "应用";
            this.btnSubmit.Click += new System.EventHandler(this.btnSubmit_Click);
            // 
            // labelControl1
            // 
            this.labelControl1.Location = new System.Drawing.Point(27, 20);
            this.labelControl1.Name = "labelControl1";
            this.labelControl1.Size = new System.Drawing.Size(50, 18);
            this.labelControl1.TabIndex = 0;
            this.labelControl1.Text = "订单号:";
            // 
            // TabOrder
            // 
            this.TabOrder.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.TabOrder.Location = new System.Drawing.Point(3, 66);
            this.TabOrder.MultiLine = DevExpress.Utils.DefaultBoolean.True;
            this.TabOrder.Name = "TabOrder";
            this.TabOrder.SelectedTabPage = this.PageOrder;
            this.TabOrder.Size = new System.Drawing.Size(1416, 671);
            this.TabOrder.TabIndex = 2;
            this.TabOrder.TabPages.AddRange(new DevExpress.XtraTab.XtraTabPage[] {
            this.PageOrder});
            // 
            // PageOrder
            // 
            this.PageOrder.Controls.Add(this.GridOrder);
            this.PageOrder.Name = "PageOrder";
            this.PageOrder.Size = new System.Drawing.Size(1409, 635);
            this.PageOrder.Text = "xtraTabPage1";
            // 
            // GridOrder
            // 
            this.GridOrder.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.GridOrder.ContextMenuStrip = this.cMenuItems;
            this.GridOrder.Location = new System.Drawing.Point(4, 4);
            this.GridOrder.MainView = this.ViewOrder;
            this.GridOrder.Name = "GridOrder";
            this.GridOrder.Size = new System.Drawing.Size(1402, 628);
            this.GridOrder.TabIndex = 0;
            this.GridOrder.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] {
            this.ViewOrder});
            // 
            // cMenuItems
            // 
            this.cMenuItems.ImageScalingSize = new System.Drawing.Size(20, 20);
            this.cMenuItems.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.MenuAdd,
            this.toolStripMenuItem1,
            this.MenuDel,
            this.toolStripMenuItem2,
            this.MenuRefresh,
            this.toolStripMenuItem4});
            this.cMenuItems.Name = "contextMenuStrip1";
            this.cMenuItems.Size = new System.Drawing.Size(113, 100);
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
            // MenuRefresh
            // 
            this.MenuRefresh.Image = ((System.Drawing.Image)(resources.GetObject("MenuRefresh.Image")));
            this.MenuRefresh.Name = "MenuRefresh";
            this.MenuRefresh.Size = new System.Drawing.Size(112, 26);
            this.MenuRefresh.Text = "刷新";
            this.MenuRefresh.Click += new System.EventHandler(this.MenuRefresh_Click);
            // 
            // toolStripMenuItem4
            // 
            this.toolStripMenuItem4.Name = "toolStripMenuItem4";
            this.toolStripMenuItem4.Size = new System.Drawing.Size(109, 6);
            // 
            // ViewOrder
            // 
            this.ViewOrder.GridControl = this.GridOrder;
            this.ViewOrder.Name = "ViewOrder";
            // 
            // PanelOrderTotal
            // 
            this.PanelOrderTotal.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.PanelOrderTotal.Controls.Add(this.totalPanel);
            this.PanelOrderTotal.Controls.Add(this.curPanel);
            this.PanelOrderTotal.Controls.Add(this.labelControl28);
            this.PanelOrderTotal.Controls.Add(this.labelControl10);
            this.PanelOrderTotal.Location = new System.Drawing.Point(3, 740);
            this.PanelOrderTotal.Name = "PanelOrderTotal";
            this.PanelOrderTotal.Size = new System.Drawing.Size(1417, 105);
            this.PanelOrderTotal.TabIndex = 45;
            // 
            // totalPanel
            // 
            this.totalPanel.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.totalPanel.Location = new System.Drawing.Point(107, 60);
            this.totalPanel.Name = "totalPanel";
            this.totalPanel.Size = new System.Drawing.Size(1301, 30);
            this.totalPanel.TabIndex = 79;
            // 
            // curPanel
            // 
            this.curPanel.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.curPanel.Location = new System.Drawing.Point(107, 15);
            this.curPanel.Name = "curPanel";
            this.curPanel.Size = new System.Drawing.Size(1301, 30);
            this.curPanel.TabIndex = 78;
            // 
            // labelControl28
            // 
            this.labelControl28.Appearance.Font = new System.Drawing.Font("Tahoma", 11F, System.Drawing.FontStyle.Bold);
            this.labelControl28.Appearance.Options.UseFont = true;
            this.labelControl28.Location = new System.Drawing.Point(5, 60);
            this.labelControl28.Name = "labelControl28";
            this.labelControl28.Size = new System.Drawing.Size(87, 23);
            this.labelControl28.TabIndex = 73;
            this.labelControl28.Text = "整单汇总:";
            // 
            // labelControl10
            // 
            this.labelControl10.Appearance.Font = new System.Drawing.Font("Tahoma", 11F, System.Drawing.FontStyle.Bold);
            this.labelControl10.Appearance.Options.UseFont = true;
            this.labelControl10.Location = new System.Drawing.Point(6, 16);
            this.labelControl10.Name = "labelControl10";
            this.labelControl10.Size = new System.Drawing.Size(87, 23);
            this.labelControl10.TabIndex = 36;
            this.labelControl10.Text = "当前页签:";
            // 
            // YLOrderForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1422, 853);
            this.Controls.Add(this.PanelOrderTotal);
            this.Controls.Add(this.TabOrder);
            this.Controls.Add(this.PanelOrderHeader);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "YLOrderForm";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text = "遗留单修改器";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            ((System.ComponentModel.ISupportInitialize)(this.PanelOrderHeader)).EndInit();
            this.PanelOrderHeader.ResumeLayout(false);
            this.PanelOrderHeader.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.TabOrder)).EndInit();
            this.TabOrder.ResumeLayout(false);
            this.PageOrder.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.GridOrder)).EndInit();
            this.cMenuItems.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.ViewOrder)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.PanelOrderTotal)).EndInit();
            this.PanelOrderTotal.ResumeLayout(false);
            this.PanelOrderTotal.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private DevExpress.XtraEditors.PanelControl PanelOrderHeader;
        private DevExpress.XtraEditors.LabelControl lblOrdDate;
        private DevExpress.XtraEditors.LabelControl labelControl8;
        private DevExpress.XtraEditors.LabelControl lblOtp;
        private DevExpress.XtraEditors.LabelControl labelControl6;
        private DevExpress.XtraEditors.LabelControl lblPONumber;
        private DevExpress.XtraEditors.LabelControl labelControl4;
        private DevExpress.XtraEditors.LabelControl lblOrdNo;
        private DevExpress.XtraEditors.SimpleButton btnSubmit;
        private DevExpress.XtraEditors.LabelControl labelControl1;
        private DevExpress.XtraTab.XtraTabControl TabOrder;
        private DevExpress.XtraTab.XtraTabPage PageOrder;
        private DevExpress.XtraEditors.PanelControl PanelOrderTotal;
        private System.Windows.Forms.FlowLayoutPanel totalPanel;
        private System.Windows.Forms.FlowLayoutPanel curPanel;
        private DevExpress.XtraEditors.LabelControl labelControl28;
        private DevExpress.XtraEditors.LabelControl labelControl10;
        private DevExpress.XtraGrid.GridControl GridOrder;
        private DevExpress.XtraGrid.Views.Grid.GridView ViewOrder;
        private System.Windows.Forms.ContextMenuStrip cMenuItems;
        private System.Windows.Forms.ToolStripMenuItem MenuAdd;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem MenuDel;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem2;
        private System.Windows.Forms.ToolStripMenuItem MenuRefresh;
        private DevExpress.Utils.ToolTipController tipOriginal;
        private System.Windows.Forms.ToolStripSeparator toolStripMenuItem4;
        private DevExpress.XtraEditors.SimpleButton btnDelAll;
    }
}