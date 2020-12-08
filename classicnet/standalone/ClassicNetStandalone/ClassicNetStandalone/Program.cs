using System;
using System.Diagnostics;
using System.IO;
using System.Timers;
using System.Text;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using WatsonWebsocket;

namespace ClassicNetStandalone
{
    class Program
    {
        const int OUTPUT_INDEX = 0;
        const double OUTPUT_FREQUENCY = 1000.0 / 60.0;

        const int INPUT_INDEX = 64;
        const double INPUT_FREQUENCY = 1000.0 / 60.0;
        const int MAX_INPUT_QUEUE = 4;

        static string server_address = "localhost:8080";
        static string pico_path = "C:\\Program Files (x86)\\PICO-8\\pico8.exe";

        static WatsonWsClient connection;
        //static Timer interval_in;
        //static Timer interval_out;

        static string initMessage;

        static StreamWriter picoin;

        static bool DEBUG = false;

        static void Main(string[] args)
        {
            if (args.Length > 0)
            {
                if (args[0] == "-d")
                {
                    DEBUG = true;
                    args = args.Skip(1).ToArray();
                }
                server_address = args[0];
            }
            else
            {
                Console.Error.WriteLine("Warning: No server name specified, defaulting to localhost:8080");
            }

            if (args.Length > 1)
            {
                pico_path = args[1];
            }

            string sock_addr = "wss://" + server_address;
            if (server_address.Contains("localhost"))
                sock_addr = "ws://" + server_address;

            connection = new WatsonWsClient(new System.Uri(sock_addr));
            connection.ServerConnected += OnOpen;
            connection.ServerDisconnected += OnClose;
            connection.MessageReceived += OnMessage;
            connection.Start();

            /*
            interval_out = new Timer(OUTPUT_FREQUENCY);
            interval_out.Elapsed += PicoInterface_Output;
            interval_out.AutoReset = true;
            interval_out.Start();

            interval_in = new Timer(INPUT_FREQUENCY);
            interval_in.Elapsed += PicoInterface_Input;
            interval_in.AutoReset = true;
            interval_in.Start();
            */

            Process pico = new Process();
            
            Console.Error.WriteLine("Launching pico8 at: " + pico_path);
            string cart_path = "classicnet.p8";
            if (DEBUG) cart_path = "../../../../../../" + cart_path;
            pico.StartInfo.FileName = pico_path;
            pico.StartInfo.Arguments = "-run " + AppDomain.CurrentDomain.BaseDirectory + cart_path;
            pico.StartInfo.UseShellExecute = false;
            pico.StartInfo.RedirectStandardInput = true;
            pico.StartInfo.StandardInputEncoding = Encoding.UTF8;
            pico.StartInfo.RedirectStandardOutput = true;
            pico.OutputDataReceived += PicoInterface_Output;
            pico.Start();
            pico.BeginOutputReadLine();

            picoin = pico.StandardInput;
            picoin.WriteLine();

            pico.WaitForExit();

            picoin.Dispose();
            pico.Dispose();
            if(connection != null)
                connection.Dispose();
        }

        private static void PicoInterface_Output(object sender, DataReceivedEventArgs args)
        {
            if (args.Data == null) return;

            if (args.Data == "f")
            {
                PicoInterface_Input();
                return;
            }
            ProcessOutput(args.Data);
        }

        private static void PicoInterface_Input()
        {
            if (picoin == null) return;
            if (inputQueue.Count > 0)
            {
                picoin.WriteLine(inputQueue.Dequeue());
            }
            else
            {
                picoin.WriteLine();
            }
        }

        static async Task OnOpen()
        {
            Console.Error.WriteLine("Connected to server");
            
        }

        static async Task OnMessage(byte[] args)
        {
            string data = Encoding.UTF8.GetString(args);
            Console.Error.WriteLine("Server message: " + data + " received");

            ProcessInput(data);
        }

        static async Task OnClose()
        {
            Console.Error.WriteLine("Disconnected from server");
        }

        static void ProcessOutput(string outputMessage)
        {
            Console.Error.WriteLine("Outgoing message: " + outputMessage);

            if (outputMessage.Split(",")[0] == "cartload")
            {
                Console.Error.WriteLine("Init Message: " + initMessage);
                inputQueue.Enqueue(initMessage);
                outputMessage = "disconnect,1,-2," + initMessage.Split(",")[3];
            }

            connection.SendAsync(Encoding.UTF8.GetBytes(outputMessage));
        }

        static Queue<string> inputQueue = new Queue<string>();

        static void ProcessInput(string message)
        {
            string[] pmessage = message.Split(",", 3);
            string mtype = pmessage[0];
            bool reliable = pmessage[1] == "1";

            if (mtype == "init")
            {
                initMessage = message;
            }

            if (!reliable)
            {
                inputQueue = new Queue<string>(inputQueue.Where((i) => i.Split(",")[0] != mtype));
            }
            if(mtype!="init" && (inputQueue.Count <= MAX_INPUT_QUEUE || reliable))
            {
                inputQueue.Enqueue(message);
            }
        }
    }
}
