using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml;
using System.Collections;

namespace ServerForm
{
    public partial class ServerForm : Form
    {
        private static string m_ctrlCodeKey = "";
        private static int PORT = 8888;
        private string m_processName = "GameServer.exe";
        public string m_winTitle = "GameServerForm";
        private int m_bgcolor = Color.LightGreen.ToArgb();
        private int m_fgcolor = Color.Black.ToArgb();
        private int m_x = 0;
        private int m_y = 0;
        private Process m_proc = null;
        private int m_maxTextLength = 500;
        private ArrayList m_logPrintCash = new ArrayList();
        private Thread m_logPrintThread = null;

        public ServerForm()
        {
            loadFormData();
            InitializeComponent();            
        }

        private void loadFormData()
        {
            string pn = Process.GetCurrentProcess().ProcessName;
            m_winTitle = pn;
            XmlDocument xmldoc = new XmlDocument();
            xmldoc.Load(pn + ".exe.xml");
            XmlNode root = xmldoc.SelectSingleNode("formInfo");
            foreach (XmlNode xn in root.ChildNodes)
            {
                XmlElement xe = (XmlElement) xn;                
                if (xe.Name.Equals("processName"))
                {
                    m_processName = xe.InnerText;
                }
                else if (xe.Name.Equals("port"))
                {
                    PORT = int.Parse(xe.InnerText);
                }
                else if (xe.Name.Equals("bgcolor"))
                {
                    m_bgcolor = int.Parse(xe.InnerText);
                }
                else if (xe.Name.Equals("fgcolor"))
                {
                    m_fgcolor = int.Parse(xe.InnerText);
                }
                else if (xe.Name.Equals("localx"))
                {
                    m_x = int.Parse(xe.InnerText);
                }
                else if (xe.Name.Equals("localy"))
                {
                    m_y = int.Parse(xe.InnerText);
                }
            }
        }

        private void saveFormData()
        {
            XmlDocument xmldoc = new XmlDocument();
            xmldoc.Load(m_winTitle + ".exe.xml");
            XmlNode root = xmldoc.SelectSingleNode("formInfo");
            foreach (XmlNode xn in root.ChildNodes)
            {
                XmlElement xe = (XmlElement)xn;
                if (xe.Name.Equals("bgcolor"))
                {
                    xe.InnerText = m_bgcolor + "";
                }
                else if (xe.Name.Equals("fgcolor"))
                {
                    xe.InnerText = m_fgcolor + "";
                }
                else if (xe.Name.Equals("localx"))
                {
                    xe.InnerText = this.Location.X + "";
                }
                else if (xe.Name.Equals("localy"))
                {
                    xe.InnerText = this.Location.Y + "";
                }
            }
            xmldoc.Save(m_winTitle + ".exe.xml");
        }

        private void updateFormView()
        {
            this.m_logTextBox.BackColor = Color.FromArgb(m_bgcolor);
            this.m_logTextBox.ForeColor = Color.FromArgb(m_fgcolor);
            this.Text = m_winTitle;
            this.Location = new Point(m_x, m_y);
        }

        private void sendCtrlCode(int ctrlcode, int len, string text)
        {
            MyThread myThread = new MyThread(ctrlcode, len, text);
            Thread thread = new Thread(myThread.sendCtrlCodeByThread);
            thread.Start();
        }

        private class MyThread
        { 
            private int m_ctrlcode = 0;
            private int m_len = 0;
            private string m_text = null;

            public MyThread(int ctrlcode, int len, string text)
            {
                this.m_ctrlcode = ctrlcode;
                this.m_len = len;
                this.m_text = text;
            }

            public void sendCtrlCodeByThread()
            {
                IPAddress ipAddress = IPAddress.Parse("127.0.0.1");
                IPEndPoint ipEndPoint = new IPEndPoint(ipAddress, PORT);
                Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                try
                {
                    socket.Connect(ipEndPoint);
                    Packet packet = new Packet(new byte[m_len]);
                    packet.writeString("&$@#");
                    packet.writeString(m_ctrlCodeKey);
                    packet.writeInt(m_ctrlcode);
                    if (m_text != null)
                    {
                        packet.writeString(m_text);
                    }
                    packet.setPacketSize();
                    byte[] pPacket = packet.getBuffByteArray();
                    socket.Send(pPacket);
                    socket.Disconnect(true);
                }
                catch
                {
                    MessageBox.Show("外壳与服务器通信失败！！！", "Error");
                }
                finally
                {
                    socket.Close();
                    socket.Dispose();
                    socket = null;
                }
            }
        }

        private Boolean initProcess()
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = m_processName,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                RedirectStandardInput = true
            };
            m_proc = new Process();
            m_proc.OutputDataReceived += new DataReceivedEventHandler(SetOutputHandler);
            m_proc.ErrorDataReceived += new DataReceivedEventHandler(SetOutputHandler);
            m_proc.StartInfo = startInfo;
            try
            {
                m_proc.Start();
                m_proc.BeginOutputReadLine();
                m_proc.BeginErrorReadLine();
            }
            catch (Exception ee)
            {
                this.m_logTextBox.AppendText("服务器启动失败了！！！！！！\r\n");
                this.m_logTextBox.AppendText(ee.Message + "\r\n");
                if (m_proc != null)
                {
                    m_proc.Close();
                    m_proc = null;
                }
                return false;
            }
            return true;
        }

        private void m_reloadBtn_Click(object sender, EventArgs e)
        {
            sendCtrlCode(0, 1024, null);            
        }

        private void SetOutputHandler(object sendingProcess, DataReceivedEventArgs outLine)
        {
            if (!String.IsNullOrEmpty(outLine.Data) && !this.m_showtraceCheckbox.Checked)
            {
                //delegateUpdateText(outLine.Data);
                m_logPrintCash.Add(outLine.Data);
                if (m_logPrintThread == null)
                {
                    m_logPrintThread = new Thread(printLogThreadWork);
                    m_logPrintThread.Start();
                }
            }
        }

        private void printLogThreadWork()
        {
            while (m_logPrintCash.Count > 0)
            {
                string logData = (string) m_logPrintCash[0];
                m_logPrintCash.RemoveAt(0);
                delegateUpdateText(logData);
                Thread.Sleep(30);

                if (this.m_showtraceCheckbox.Checked && m_logPrintCash.Count > 0)
                {
                    m_logPrintCash.Clear();
                }
            }

            m_logPrintThread = null;
        }

        private delegate void updateTextBox(string text);
        private void delegateUpdateText(string text)
        {
            if (this.m_logTextBox == null || this.m_logTextBox.IsDisposed)
            {
                return;
            }
            if (String.IsNullOrWhiteSpace(m_ctrlCodeKey) && text.Contains("ctrl_code_key:"))   //去获取key值
            { 
                Int32 sIndex = text.IndexOf("ctrl_code_key:");
                m_ctrlCodeKey = text.Substring(sIndex + 14, 32);
            }
            if (this.m_logTextBox.InvokeRequired)
            {
                updateTextBox utb = new updateTextBox(delegateUpdateText);
                //this.m_logTextBox.Invoke(utb, new object[] { text });
                //TODO有点问题，一桢以内打印太多的信息，会导致外壳卡死
                this.m_logTextBox.BeginInvoke(utb, new object[] { text });
            }
            else
            {                                
                if (this.m_logTextBox.Lines.Length > m_maxTextLength)
                {
                    int moreLines = this.m_logTextBox.Lines.Length - m_maxTextLength;
                    string[] lines = this.m_logTextBox.Lines;
                    Array.Copy(lines, moreLines, lines, 0, m_maxTextLength);
                    Array.Resize(ref lines, m_maxTextLength);
                    this.m_logTextBox.Lines = lines;
                }
                this.m_logTextBox.AppendText(text + "\r\n");
            }
        }

        private void m_clearBtn_Click(object sender, EventArgs e)
        {
            if (this.m_logTextBox != null)
            {
                this.m_logTextBox.Clear();
            }
        }

        private string m_oldDebugStr = "print(\"debug\")";
        private void m_keyPress(object sender, KeyEventArgs e)
        {
            if (e.KeyCode.ToString().Equals("F9"))
            {
                new Form2(this, m_oldDebugStr).Show();
            }
        }

        public void sendDebugScript(string debugStr)
        {
            m_oldDebugStr = debugStr;
            sendCtrlCode(2, 655350, debugStr);
        }

        private void ServerForm_shown(object sender, EventArgs e)
        {
            updateFormView();
            initProcess();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (MessageBox.Show("你确认要退出该程序吗？", "退出程序",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question,
                MessageBoxDefaultButton.Button2) == DialogResult.Yes)
            {
                saveFormData();
                if (m_logPrintThread != null)
                {
                    m_logPrintThread.Abort();
                }
                if (m_proc != null && !m_proc.HasExited)
                {                    
                    sendCtrlCode(1, 1024, null);
                    saveFormData();
                    m_proc.WaitForExit();
                    if (m_proc != null)
                    {
                        m_proc.Close();
                        m_proc = null;
                    }                   
                }
                base.OnFormClosing(e);
            }
            else
            {
                e.Cancel = true;
            }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            ColorDialog loColorForm = new ColorDialog();
            if (loColorForm.ShowDialog() == DialogResult.OK)
            {
                Color loResultColor = loColorForm.Color;
                this.m_logTextBox.BackColor = loResultColor;
                m_bgcolor = loResultColor.ToArgb();
            }            
        }

        private void button2_Click(object sender, EventArgs e)
        {
            ColorDialog loColorForm = new ColorDialog();
            if (loColorForm.ShowDialog() == DialogResult.OK)
            {
                Color loResultColor = loColorForm.Color;
                this.m_logTextBox.ForeColor = loResultColor;
                m_fgcolor = loResultColor.ToArgb();
            }
        }
    }
}
