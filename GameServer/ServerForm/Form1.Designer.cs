namespace ServerForm
{
    partial class ServerForm
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.m_logTextBox = new System.Windows.Forms.TextBox();
            this.panel1 = new System.Windows.Forms.Panel();
            this.button2 = new System.Windows.Forms.Button();
            this.button1 = new System.Windows.Forms.Button();
            this.m_showtraceCheckbox = new System.Windows.Forms.CheckBox();
            this.m_clearBtn = new System.Windows.Forms.Button();
            this.m_reloadBtn = new System.Windows.Forms.Button();
            this.panel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // m_logTextBox
            // 
            this.m_logTextBox.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.m_logTextBox.BackColor = System.Drawing.Color.LightGreen;
            this.m_logTextBox.Location = new System.Drawing.Point(0, 0);
            this.m_logTextBox.MaxLength = 100;
            this.m_logTextBox.Multiline = true;
            this.m_logTextBox.Name = "m_logTextBox";
            this.m_logTextBox.ReadOnly = true;
            this.m_logTextBox.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.m_logTextBox.Size = new System.Drawing.Size(607, 384);
            this.m_logTextBox.TabIndex = 0;
            // 
            // panel1
            // 
            this.panel1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.panel1.BackColor = System.Drawing.SystemColors.ControlLight;
            this.panel1.Controls.Add(this.button2);
            this.panel1.Controls.Add(this.button1);
            this.panel1.Controls.Add(this.m_showtraceCheckbox);
            this.panel1.Controls.Add(this.m_clearBtn);
            this.panel1.Controls.Add(this.m_reloadBtn);
            this.panel1.Location = new System.Drawing.Point(0, 383);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(607, 59);
            this.panel1.TabIndex = 1;
            // 
            // button2
            // 
            this.button2.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.button2.Location = new System.Drawing.Point(184, 21);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(75, 23);
            this.button2.TabIndex = 4;
            this.button2.Text = "前景颜色";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Click += new System.EventHandler(this.button2_Click);
            // 
            // button1
            // 
            this.button1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.button1.Location = new System.Drawing.Point(265, 21);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(75, 23);
            this.button1.TabIndex = 3;
            this.button1.Text = "背景颜色";
            this.button1.UseVisualStyleBackColor = true;
            this.button1.Click += new System.EventHandler(this.button1_Click);
            // 
            // m_showtraceCheckbox
            // 
            this.m_showtraceCheckbox.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left)));
            this.m_showtraceCheckbox.AutoSize = true;
            this.m_showtraceCheckbox.Location = new System.Drawing.Point(32, 21);
            this.m_showtraceCheckbox.Name = "m_showtraceCheckbox";
            this.m_showtraceCheckbox.Size = new System.Drawing.Size(84, 16);
            this.m_showtraceCheckbox.TabIndex = 2;
            this.m_showtraceCheckbox.Text = "不显示输出";
            this.m_showtraceCheckbox.UseVisualStyleBackColor = true;
            // 
            // m_clearBtn
            // 
            this.m_clearBtn.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.m_clearBtn.Location = new System.Drawing.Point(500, 21);
            this.m_clearBtn.Name = "m_clearBtn";
            this.m_clearBtn.Size = new System.Drawing.Size(75, 23);
            this.m_clearBtn.TabIndex = 1;
            this.m_clearBtn.Text = "清除显示";
            this.m_clearBtn.UseVisualStyleBackColor = true;
            this.m_clearBtn.Click += new System.EventHandler(this.m_clearBtn_Click);
            // 
            // m_reloadBtn
            // 
            this.m_reloadBtn.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.m_reloadBtn.Location = new System.Drawing.Point(395, 21);
            this.m_reloadBtn.Name = "m_reloadBtn";
            this.m_reloadBtn.Size = new System.Drawing.Size(75, 23);
            this.m_reloadBtn.TabIndex = 0;
            this.m_reloadBtn.Text = "重新载入";
            this.m_reloadBtn.UseVisualStyleBackColor = true;
            this.m_reloadBtn.Click += new System.EventHandler(this.m_reloadBtn_Click);
            // 
            // ServerForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(607, 441);
            this.Controls.Add(this.panel1);
            this.Controls.Add(this.m_logTextBox);
            this.KeyPreview = true;
            this.Name = "ServerForm";
            this.Text = "GameServerForm";
            this.Shown += new System.EventHandler(this.ServerForm_shown);
            this.KeyUp += new System.Windows.Forms.KeyEventHandler(this.m_keyPress);
            this.panel1.ResumeLayout(false);
            this.panel1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox m_logTextBox;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.Button m_reloadBtn;
        private System.Windows.Forms.Button m_clearBtn;
        private System.Windows.Forms.CheckBox m_showtraceCheckbox;
        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.Button button2;
    }
}

