using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ServerForm
{
    class Packet
    {
        private byte[] m_byteArray = null;
        private int m_offset = 0;

        public Packet()
        {

        }

        public Packet(byte[] byteArray)
        {
            m_byteArray = byteArray;
            m_offset = 4;
        }

        public byte[] getBuffByteArray()
        {
            if (m_offset > 0 && m_offset < m_byteArray.Length)
            {
                //转移数据，减少数据量传送
                byte[] tempByte = new byte[m_offset];
                for (int i = 0; i < m_offset; i++)
                {
                    tempByte[i] = m_byteArray[i];
                }
                return tempByte;
            }
            return m_byteArray;
        }

        public void writeInt(int value)
        {
            byte[] byteArray = BitConverter.GetBytes(value);
            for (int i = 0; i < byteArray.Length; i++)
            {
                m_byteArray[m_offset++] = byteArray[i];
            }
        }

        public void writeUInt(uint value)
        {
            byte[] byteArray = BitConverter.GetBytes(value);
            for (int i = 0; i < byteArray.Length; i++)
            {
                m_byteArray[m_offset++] = byteArray[i];
            }
        }

        public void writeString(String value)
        {
            byte[] strByte = Encoding.ASCII.GetBytes(value);
            writeUInt((uint)strByte.Length);
            for (int i = 0; i < strByte.Length; i++)
            {
                m_byteArray[m_offset++] = strByte[i];
            }
        }

        public void setPacketSize()
        {
            byte[] byteArray = BitConverter.GetBytes(m_offset);
            for (int i = 0; i < 4; i++)
            {
                m_byteArray[i] = byteArray[i];
            }
        }
    }
}
