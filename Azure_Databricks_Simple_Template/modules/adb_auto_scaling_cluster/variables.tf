variable "azure_databricks_workspace_url" {
  type        = string
  description = "(Obrigatório) URL do workspace onde o cluster que será criado"
}

variable "cluster_name" {
  type        = string
  description = "(Obrigatório) Nome do cluster que será criado com este módulo"
  default     = ""
}

variable "spark_version" {
  type        = string
  description = "(Opcional) Versão do Spark que será utilizada no cluster criado (se não especificada, será utilizada a mais recente LTS)"
  default     = null
}

variable "node_type_id" {
  type        = string
  description = "(Opcional) Nó que será utilizado no cluster (se não especificado, será o menor disponível)"
  default     = null
}

variable "autotermination_minutes" {
  type        = number
  description = "(Opcional) Número de minutos para o auto-terminate do cluster, se não especificado, será 30 minutos"
  default     = null
}

variable "min_auto_scaling" {
  type        = number
  description = "(Opcional) Número mínimo de nós para o autoscaling do cluster, se não especificado, será 1"
  default     = null
}

variable "max_auto_scaling" {
  type        = number
  description = "(Opcional) Número máximo de nós para o autoscaling do cluster, se não especificado, será 3"
  default     = null
}

variable "num_workers" {
  type        = number
  description = "(Opcional) Número de nós em cluster sem auto-scaling se não especificado, será 0 (single node)"
  default     = null
}

variable "auto_scaling_cluster" {
  type        = bool
  description = "(Opcional) Flag que indica se o cluster terá autoscaling ou será fixo"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Opcional) Mapa de tags a serem aplicadas no cluster"
  default     = null
}
