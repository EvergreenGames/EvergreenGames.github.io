using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using WatsonWebsocket;

namespace ClassicNetStandalone
{

    class Program
    {
        const string DEFAULT_SERVER_ADDRESS = "classicnet.tk";
        const string DEFAULT_SERVER_ADDRESS_DEBUG = "localhost:8080";

        const int OUTPUT_INDEX = 0;
        const double OUTPUT_FREQUENCY = 1000.0 / 60.0;

        const int INPUT_INDEX = 64;
        const double INPUT_FREQUENCY = 1000.0 / 60.0;
        const int MAX_INPUT_QUEUE = 4;

        static string server_address = "localhost:8080";
        static string pico_path = "C:\\Program Files (x86)\\PICO-8\\pico8.exe";

        static WatsonWsClient connection;
        static bool connected = false;
        static AutoResetEvent waitForConnnection = new AutoResetEvent(false);

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
                }
            }

            while (!File.Exists(pico_path))
            {
                Console.Error.WriteLine("Pico 8 Executable not found. Please specify a path to pico8.exe.");
                pico_path = Console.ReadLine();
            }

            Console.Error.WriteLine("Press enter to connect, or specify a custom server url.");
            server_address = Console.ReadLine();
            if (server_address == "")
                server_address = DEBUG ? DEFAULT_SERVER_ADDRESS_DEBUG : DEFAULT_SERVER_ADDRESS;

            Console.Error.WriteLine("Connecting...");

            string sock_addr = "wss://" + server_address;
            if (server_address.Contains("localhost"))
                sock_addr = "ws://" + server_address;

            connection = new WatsonWsClient(new System.Uri(sock_addr));
            connection.ServerConnected += OnOpen;
            connection.ServerDisconnected += OnClose;
            connection.MessageReceived += OnMessage;
            connection.Start();

            waitForConnnection.WaitOne();

            Process pico = new Process();
            
            //Console.Error.WriteLine("Launching pico8 at: " + pico_path);
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
            Console.Error.WriteLine("Server located");
        }

        static async Task OnMessage(byte[] args)
        {
            string data = Encoding.UTF8.GetString(args);
            if(DEBUG) Console.Error.WriteLine("Server message: " + data + " received");

            ProcessInput(data);
        }

        static async Task OnClose()
        {
            Console.Error.WriteLine("Disconnected from server");
            connected = false;
        }

        static void ProcessOutput(string outputMessage)
        {
            if(DEBUG) Console.Error.WriteLine("Outgoing message: " + outputMessage);

            if (outputMessage.Split(",")[0] == "cartload")
            {
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
                connected = true;
                waitForConnnection.Set();
                Console.Error.WriteLine("Connected!");
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
