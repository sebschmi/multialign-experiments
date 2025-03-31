import os, traceback

# Safe formatting

class SafeDict(dict):
    def __missing__(self, key):
        return '{' + key + '}'

def safe_format(str, **kwargs):
    return str.format_map(SafeDict(kwargs))

def safe_expand(str, **kwargs):
    items = []
    for key, values in kwargs.items():
        if type(values) is str or type(values) is not list:
            values = [values]
        items.append([(key, value) for value in values])

    for combination in itertools.product(*items):
        yield safe_format(str, **dict(combination))

def wildcard_format(str, wildcards):
    return str.format(**dict(wildcards.items()))

BASEDIR = os.getcwd()
if "datadir" in config:
    BASEDIR = config["datadir"]
print(f"BASEDIR = {BASEDIR}")

DATADIR = os.path.join(BASEDIR, "data")
AURINKO_THREADS = 256
NORMAL_THREADS = 56

# Locking does not work properly on the cluster, so we need to fetch tools one at a time
workflow.global_resources["cargo_fetch"] = 1
workflow.global_resources["download"] = 4

DOWNLOAD_DIR = os.path.join(DATADIR, "downloads")
EMERALD_ZIP = os.path.join(DOWNLOAD_DIR, "emerald.zip")
EMERALD_DIR = os.path.join(DOWNLOAD_DIR, "emerald")

SOFTWARE_DIR = os.path.join(DATADIR, "software")
MULTIALIGN_DIR = os.path.join(SOFTWARE_DIR, "multialign")
MULTIALIGN_MANIFEST = os.path.join(MULTIALIGN_DIR, "Cargo.toml")
MULTIALIGN_BINARY = os.path.join(MULTIALIGN_DIR, "target", "release", "multialign")

#================================================
#=== REPORT =====================================
#================================================

localrules: report_all
rule report_all:
    input:  multialign = MULTIALIGN_BINARY,
            downloads = EMERALD_DIR,

#================================================
#=== DOWNLOADS ==================================
#================================================

rule extract_emerald_zip:
    input:  EMERALD_ZIP,
    output: directory(EMERALD_DIR),
    conda:  "config/conda-extract-env.yml"
    resources:
            mem_mb = 10_000,
    shell:  """
        unzip -u '{input}' -d '{output}'
        """

localrules: download_emerald_zip
rule download_emerald_zip:
    output: EMERALD_ZIP,
    conda:  "config/conda-download-env.yml"
    resources:
            download = 1,
    shell:  """
        curl -L -o '{output}' 'https://figshare.com/ndownloader/files/40046686'
        """

#================================================
#=== INSTALL ====================================
#================================================

localrules: download_multialign
rule download_multialign:
    output: manifest = MULTIALIGN_MANIFEST,
    params: software_dir = SOFTWARE_DIR,
            software_subdir = MULTIALIGN_DIR,
    conda:  "config/conda-rust-env.yml"
    threads: 1
    resources:
            cargo_fetch = 1,
    shell:  """
        mkdir -p '{params.software_dir}'
        cd '{params.software_dir}'

        rm -rf '{params.software_subdir}'
        git clone https://github.com/sebschmi/multialign '{params.software_subdir}'
        cd '{params.software_subdir}'
        git checkout a4ea5a4c0e633f2020b3de4a2a52352a2ea3a549

        cargo fetch
        """

rule build_multialign:
    input:  manifest = MULTIALIGN_MANIFEST,
    output: binary = MULTIALIGN_BINARY,
    params: software_subdir = MULTIALIGN_DIR,
    conda:  "config/conda-rust-env.yml"
    threads: NORMAL_THREADS
    resources:
            mem_mb = 10_000,
            runtime = 60,
    shell:  """
        cd '{params.software_subdir}'
        cargo build --release -j {threads} --offline
        """
