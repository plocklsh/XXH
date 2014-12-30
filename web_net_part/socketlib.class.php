<?php
    class socketlib
    {
        private static $rpcConfig = array
        (
            "gls" => array
            (
                "host" => "127.0.0.1",
                "port" => 8889,
                "key" => "kpgdakjg4546joiiru2&*%&%&r32",
            ),
        );
        
        //远程调用游戏服务器 array([0] => retcode, [2] => data)
        public static function rpc($cmd, $data, $servername)
        {        
            $conf = socketlib::$rpcConfig[$servername];
            $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
            if (!$socket)
            {
                echo("socket_create() failed\nError:" . socket_strerror($socket));
                return array(-100001, "socket_create() failed\nError:" . socket_strerror($socket));
            }
            $result = socket_connect($socket, $conf["host"], $conf["port"]);
            if (!$result)
            {
                echo("socket_create() failed\nError:" . socket_strerror($result));
                return array(-100002, "socket_create() failed\nError:" . socket_strerror($result));
            }
            //构造数据包
            $data_str = json_encode(array(cmd=>$cmd, data=>$data));
            $data_md5 = md5($data_str . $conf["key"]);            
            $sendPack = new packet("");
            $sendPack->writeString("op_php");   //协议头
            $sendPack->writeString($data_md5);
            $sendPack->writeString($data_str);
            $sendPack->setPackSize();
            if (!socket_write($socket, $sendPack->getPack(), strlen($sendPack->getPack())))
            {
                echo("socket_write() failed\nError:" . socket_strerror($socket));
                return array(-100003, "socket_write() failed\nError:" . socket_strerror($socket));
            }            
            
            //等待回复        
            $start_time = socketlib::getmicrotime();
            socket_set_nonblock($socket);
            $time_out = 10 * 1000;  //10秒钟内还没有回复，则不管了
            $recv_buff = "";
            while((socketlib::getmicrotime() - $start_time) * 1000 < $time_out)
            {
                $recv_tmp = "";
                if (false != ($bytes = @socket_recv($socket, $recv_tmp, 1024, MSG_WAITALL)))
                {
                    $recv_buff = $recv_buff . $recv_tmp;
                    if (strlen($recv_buff) > 4)
                    {
                        $len = ord(substr($recv_buff, 0, 4));
                        if ($len <= strlen($recv_buff))   
                        {
                            $recv_buff = substr($recv_buff, 0, $len);
                            break;
                        }
                    }
                }                
                usleep(1);  //别太着急
            }
            socket_close($socket);
            if (strcmp($recv_buff, "") == 0)
            {
                return array(-100004, "socket_recv() time out\n");
            }
            
            //解析数据包
            $recvPack = new packet($recv_buff);
            $recvPack->readInt();   //前移4个字节
            $recvPack->readString();    //读出协议头
            $ret = $recvPack->readString();
            $retData = json_decode($ret);
            if ($retData == null)
            {
                return array(-100005, "json_decode() failed");
            }
            return $retData;
        }
        
        private static function getmicrotime()
        {   
            list($usec, $sec) = explode(" ",microtime());   
            return ((float)$usec + (float)$sec);   
        }
    }
    
    class packet
    {
        private $m_point = 0;
        private $m_data = "";
        
        function packet($data)
        {
            $this->m_data = $data;
        }
        
        public function writeInt($val)
        {
            $this->m_data .= chr($val & 0xff);
            $this->m_data .= chr($val >> 8 & 0xff);
            $this->m_data .= chr($val >> 16 & 0xff);
            $this->m_data .= chr($val >> 24 & 0xff);
        }
        
        public function readInt()
        {
            if (strlen($this->m_data) < 4) die("数据包不对吧？？？！！！");
            $val = ord(substr($this->m_data, $this->m_point, 4));
            $this->m_point += 4;
            return $val;
        }
        
        public function writeString($val)
        {
            $this->writeInt(strlen($val));
            $this->m_data .= $val;
        }
        
        public function readString()
        {
            $len = $this->readInt();
            $val = substr($this->m_data, $this->m_point, $len);
            $this->m_point += $len;
            return $val;
        }
        
        public function setPackSize()
        {
            $val = strlen($this->m_data) + 4;
            $len = chr($val & 0xff);
            $len .= chr($val >> 8 & 0xff);
            $len .= chr($val >> 16 & 0xff);
            $len .= chr($val >> 24 & 0xff);
            $this->m_data = $len . $this->m_data;
        }
        
        public function getPack()
        {
            return $this->m_data;
        }
    }
?>
