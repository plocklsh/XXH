using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ServerForm
{
    public partial class Form2 : Form
    {
        private ServerForm m_parentForm = null;
        private string m_oldTextStr = "";

        public Form2(ServerForm parentForm, string oldTextStr)
        {
            this.m_parentForm = parentForm;
            this.m_oldTextStr = oldTextStr;
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (m_parentForm != null)
            {
                m_parentForm.sendDebugScript(this.textBox1.Text);
            }
        }
    }
}
