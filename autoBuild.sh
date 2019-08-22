
echo '=============== A0PreMainTime ================'

#脚本运行当前目录 
CUR_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
echo '***** A0PreMainTime file ---- '$CUR_DIR' *****' 

#默认配置release环境
currentConfigratin="release"

function compilingSetting {
	#编译A0PreMainTime
	cd Library/A0PreMainTime
	./autoTimeBuild.sh $currentConfigratin
}

#***************** Configratin ********************
function compilingConfigratinDebug {
    currentConfigratin="debug" 
    echo "> debug"
    compilingSetting
}

function compilingConfigratinRelease {
     echo "> release"
     compilingSetting
}

function compilingConfigratinOption()
{
    read -p "Please choose your configratin:" choice
    case $choice in
        1)
            compilingConfigratinRelease
            break
            ;;
        2)
            compilingConfigratinDebug
            break
            ;;
        "")
            compilingConfigratinRelease
            break
            ;;
        *)
            echo "sorry,wrong selection" 
            ;;
    esac
}
function  compilingConfigratin()
{
    while true
    do
            cat <<eof

What configratin do you want to compiling?
1. release
2. debug
Not: Enter => (release)
eof
        compilingConfigratinOption
    done
}

compilingConfigratin



